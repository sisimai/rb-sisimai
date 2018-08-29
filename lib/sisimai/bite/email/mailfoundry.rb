module Sisimai::Bite::Email
  # Sisimai::Bite::Email::MailFoundry parses a bounce email which created by
  # MailFoundry. Methods in the module are called from only Sisimai::Message.
  module MailFoundry
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/MailFoundry.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['This is a MIME encoded message'],
        rfc822:  ['Content-Type: message/rfc822'],
        error:   ['Delivery failed for the following reason:'],
      }.freeze

      def description; return 'MailFoundry'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from MailFoundry
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
        return nil unless mhead['subject'] == 'Message delivery has failed'
        return nil unless mhead['received'].any? { |a| a.include?('(MAILFOUNDRY) id ') }

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
            if e == StartingOf[:message][0]
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e == StartingOf[:rfc822][0]
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

            # Unable to deliver message to: <kijitora@example.org>
            # Delivery failed for the following reason:
            # Server mx22.example.org[192.0.2.222] failed with: 550 <kijitora@example.org> No such user here
            #
            # This has been a permanent failure.  No further delivery attempts will be made.
            v = dscontents[-1]

            if cv = e.match(/\AUnable to deliver message to: [<]([^ ]+[@][^ ]+)[>]\z/)
              # Unable to deliver message to: <kijitora@example.org>
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              recipients += 1
            else
              # Error message
              if e == StartingOf[:error][0]
                # Delivery failed for the following reason:
                v['diagnosis'] = e
              else
                # Detect error message
                next if e.empty?
                next if v['diagnosis'].nil? || v['diagnosis'].empty?
                next if e.start_with?('-')

                # Server mx22.example.org[192.0.2.222] failed with: 550 <kijitora@example.org> No such user here
                v['diagnosis'] << ' ' << e
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end
