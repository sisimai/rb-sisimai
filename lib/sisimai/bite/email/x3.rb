module Sisimai::Bite::Email
  # Sisimai::Bite::Email::X3 parses a bounce email which created by Unknown
  # MTA #3. Methods in the module are called from only Sisimai::Message.
  module X3
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/X3.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['      This is an automatically generated Delivery Status Notification.'],
        rfc822:  ['Content-Type: message/rfc822'],
      }.freeze

      def description; return 'Unknown MTA #3'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Unknown MTA #3
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
        return nil unless mhead['subject'].start_with?('Delivery status notification')
        return nil unless mhead['from'].start_with?('Mail Delivery System')

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

            # ============================================================================
            #      This is an automatically generated Delivery Status Notification.
            #
            # Delivery to the following recipients failed permanently:
            #
            #   * kijitora@example.com
            #
            #
            # ============================================================================
            #                             Technical details:
            #
            # SMTP:RCPT host 192.0.2.8: 553 5.3.0 <kijitora@example.com>... No such user here
            #
            #
            # ============================================================================
            v = dscontents[-1]

            if cv = e.match(/\A[ \t]+[*][ ]([^ ]+[@][^ ]+)\z/)
              #   * kijitora@example.com
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              recipients += 1
            else
              # Detect error message
              if cv = e.match(/\ASMTP:([^ ]+)[ ](.+)\z/)
                # SMTP:RCPT host 192.0.2.8: 553 5.3.0 <kijitora@example.com>... No such user here
                v['command'] = cv[1].upcase
                v['diagnosis'] = cv[2]

              elsif cv = e.match(/\ARouting: (.+)/)
                # Routing: Could not find a gateway for kijitora@example.co.jp
                v['diagnosis'] = cv[1]
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['status']    = Sisimai::SMTP::Status.find(e['diagnosis'])
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

