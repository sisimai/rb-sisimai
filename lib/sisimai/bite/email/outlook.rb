module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Outlook parses a bounce email which created by
  # Microsoft Outlook.com.
  # Methods in the module are called from only Sisimai::Message.
  module Outlook
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/US/Outlook.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['This is an automatically generated Delivery Status Notification'],
        rfc822:  ['Content-Type: message/rfc822'],
      }.freeze
      MessagesOf = {
        hostunknown: ['The mail could not be delivered to the recipient because the domain is not reachable'],
        userunknown: ['Requested action not taken: mailbox unavailable'],
      }.freeze

      def description; return 'Microsoft Outlook.com: https://www.outlook.com/'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end

      # X-Message-Delivery: Vj0xLjE7RD0wO0dEPTA7U0NMPTk7bD0xO3VzPTE=
      # X-Message-Info: AuEzbeVr9u5fkDpn2vR5iCu5wb6HBeY4iruBjnutBzpStnUabbM...
      def headerlist;  return ['X-Message-Delivery', 'X-Message-Info']; end

      # Parse bounce messages from Microsoft Outlook.com
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
        # :from => %r/postmaster[@]/,
        match  = 0
        match += 1 if mhead['subject'].start_with?('Delivery Status Notification')
        match += 1 if mhead['x-message-delivery']
        match += 1 if mhead['x-message-info']
        match += 1 if mhead['received'].any? { |a| a.include?('.hotmail.com') }
        return nil if match < 2

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        connvalues = 0      # (Integer) Flag, 1 if all the value of connheader have been set
        connheader = {
          'date'  => '',    # The value of Arrival-Date header
          'lhost' => '',    # The value of Reporting-MTA header
        }
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e.start_with?(StartingOf[:message][0])
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

            if connvalues == connheader.keys.size
              # This is an automatically generated Delivery Status Notification.
              #
              # Delivery to the following recipients failed.
              #
              #      kijitora@example.jp
              #
              # Final-Recipient: rfc822;kijitora@example.jp
              # Action: failed
              # Status: 5.2.2
              # Diagnostic-Code: smtp;550 5.2.2 <kijitora@example.jp>... Mailbox Full
              v = dscontents[-1]

              if cv = e.match(/\AFinal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # Final-Recipient: rfc822;kijitora@example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Bite.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              elsif cv = e.match(/\AAction:[ ]*(.+)\z/)
                # Action: failed
                v['action'] = cv[1].downcase

              elsif cv = e.match(/\AStatus:[ ]*(\d[.]\d+[.]\d+)/)
                # Status:5.2.0
                v['status'] = cv[1]
              else
                if cv = e.match(/\ADiagnostic-Code:[ ]*(.+?);[ ]*(.+)\z/)
                  # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                  v['spec'] = cv[1].upcase
                  v['diagnosis'] = cv[2]

                elsif p.start_with?('Diagnostic-Code:') && cv = e.match(/\A[ \t]+(.+)\z/)
                  # Continued line of the value of Diagnostic-Code header
                  v['diagnosis'] << ' ' << cv[1]
                  havepassed[-1] = 'Diagnostic-Code: ' << e
                end
              end
            else
              # Reporting-MTA: dns;BLU004-OMC3S13.hotmail.example.com
              # Received-From-MTA: dns;BLU436-SMTP66
              # Arrival-Date: Fri, 21 Nov 2014 14:17:34 -0800
              if cv = e.match(/\AReporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Reporting-MTA: dns;BLU004-OMC3S13.hotmail.example.com
                next unless connheader['lhost'].empty?
                connheader['lhost'] = cv[1].downcase
                connvalues += 1

              elsif cv = e.match(/\AArrival-Date:[ ]*(.+)\z/)
                # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                next unless connheader['date'].empty?
                connheader['date'] = cv[1]
                connvalues += 1
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          connheader.each_key { |a| e[a] ||= connheader[a] || '' }
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''

          if e['diagnosis'].empty?
            # No message in 'diagnosis'
            if e['action'] == 'delayed'
              # Set pseudo diagnostic code message for delaying
              e['diagnosis'] = 'Delivery to the following recipients has been delayed.'
            else
              # Set pseudo diagnostic code message
              e['diagnosis']  = 'Unable to deliver message to the following recipients, '
              e['diagnosis'] << 'due to being unable to connect successfully to the destination mail server.'
            end
          end

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

