module Sisimai::Bite::Email
  module EinsUndEins
    # Sisimai::Bite::Email::EinsUndEins parses a bounce email which created by
    # 1&1. Methods in the module are called from only Sisimai::Message.
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/EinsUndEins.pm
      require 'sisimai/bite/email'

      Re0 = {
        :from    => %r/\A["]Mail Delivery System["]/,
        :subject => %r/\AMail delivery failed: returning message to sender\z/,
      }.freeze
      Re1 = {
        :begin   => %r/\AThis message was created automatically by mail delivery software/,
        :error   => %r/\AFor the following reason:/,
        :rfc822  => %r/\A--- The header of the original message is following/,
        :endof   => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
      }.freeze
      ReFailure = {
        mesgtoobig: %r/Mail[ ]size[ ]limit[ ]exceeded/x,
      }.freeze
      Indicators = Sisimai::Bite::Email.INDICATORS

      def description; return '1&1: http://www.1and1.de'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      # X-UI-Out-Filterresults: unknown:0;
      def headerlist;  return []; end
      def pattern;     return Re0; end

      # Parse bounce messages from 1&1
      # @param         [Hash] mhead       Message headers of a bounce email
      # @options mhead [String] from      From header
      # @options mhead [String] date      Date header
      # @options mhead [String] subject   Subject header
      # @options mhead [Array]  received  Received headers
      # @options mhead [String] others    Other required headers
      # @param         [String] mbody     Message body of a bounce email
      # @return        [Hash, Nil]        Bounce data list and message/rfc822
      #                                   part or nil if it failed to parse or
      #                                   the arguments are missing
      def scan(mhead, mbody)
        return nil unless mhead
        return nil unless mbody
        return nil unless mhead['from']    =~ Re0[:from]
        return nil unless mhead['subject'] =~ Re0[:subject]

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        hasdivided.each do |e|
          if readcursor.zero?
            # Beginning of the bounce message or delivery status part
            if e =~ Re1[:begin]
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']).zero?
            # Beginning of the original message part
            if e =~ Re1[:rfc822]
              readcursor |= Indicators[:'message-rfc822']
              next
            end
          end

          if readcursor & Indicators[:'message-rfc822'] > 0
            # After "message/rfc822"
            if e.empty?
              blanklines += 1
              break if blanklines > 1
              next
            end
            rfc822list << e

          else
            # Before "message/rfc822"
            next if (readcursor & Indicators[:deliverystatus]).zero?
            next if e.empty?

            # The following address failed:
            #
            # general@example.eu
            #
            # For the following reason:
            #
            # Mail size limit exceeded. For explanation visit
            # http://postmaster.1and1.com/en/error-messages?ip=%1s
            v = dscontents[-1]

            if cv = e.match(/\A([^ ]+[@][^ ]+)\z/)
              # general@example.eu
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              recipients += 1

            elsif e =~ Re1[:error]
              # For the following reason:
              v['diagnosis'] = e

            else
              # Get error message
              if v['diagnosis']
                # Append error message strings
                v['diagnosis'] += ' ' + e
              end
            end
          end
        end
        return nil if recipients.zero?
        require 'sisimai/string'

        dscontents.map do |e|
          e['agent']       = self.smtpagent
          e['diagnosis'] ||= ''
          e['diagnosis']   = e['diagnosis'].gsub(/\A#{Re1[:error]}/, '')
          e['diagnosis']   = Sisimai::String.sweep(e['diagnosis'])

          ReFailure.each_key do |r|
            # Verify each regular expression of session errors
            next unless e['diagnosis'] =~ ReFailure[r]
            e['reason'] = r.to_s
            break
          end
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

