module Sisimai::Bite::Email
  # Sisimai::Bite::Email::EinsUndEins parses a bounce email which created by
  # 1&1. Methods in the module are called from only Sisimai::Message.
  module EinsUndEins
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/EinsUndEins.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['This message was created automatically by mail delivery software'],
        error:   ['For the following reason:'],
        rfc822:  ['--- The header of the original message is following'],
      }.freeze
      MessagesOf = { mesgtoobig: ['Mail size limit exceeded'] }.freeze

      def description; return '1&1: http://www.1and1.de'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      # X-UI-Out-Filterresults: unknown:0;
      def headerlist;  return []; end

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
        return nil unless mhead['from'].start_with?('"Mail Delivery System"')
        return nil unless mhead['subject'] == 'Mail delivery failed: returning message to sender'

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = hasdivided.shift do
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e.start_with?(StartingOf[:message][0])
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e.start_with?(StartingOf[:rfc822][0])
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
            next if (readcursor & Indicators[:deliverystatus]) == 0
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

            elsif e.start_with?(StartingOf[:error][0])
              # For the following reason:
              v['diagnosis'] = e
            else
              # Get error message and append error message strings
              v['diagnosis'] << ' ' << e if v['diagnosis']
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].to_s.gsub(/\A#{StartingOf[:error][0]}/, ''))

          MessagesOf.each_key do |r|
            # Verify each regular expression of session errors
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
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

