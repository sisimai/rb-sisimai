module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Aol parses a bounce email which created by Aol Mail.
  # Methods in the module are called from only Sisimai::Message.
  module Aol
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Aol.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['Content-Type: message/delivery-status'],
        rfc822:  ['Content-Type: message/rfc822'],
      }.freeze
      MessagesOf = {
        hostunknown: ['Host or domain name not found'],
        notaccept:   ['type=MX: Malformed or unexpected name server reply'],
      }.freeze

      def description; return 'Aol Mail: http://www.aol.com'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end

      # X-AOL-IP: 192.0.2.135
      # X-AOL-VSS-INFO: 5600.1067/98281
      # X-AOL-VSS-CODE: clean
      # x-aol-sid: 3039ac1afc14546fb98a0945
      # X-AOL-SCOLL-EIL: 1
      # x-aol-global-disposition: G
      # x-aol-sid: 3039ac1afd4d546fb97d75c6
      # X-BounceIO-Id: 9D38DE46-21BC-4309-83E1-5F0D788EFF1F.1_0
      # X-Outbound-Mail-Relay-Queue-ID: 07391702BF4DC
      # X-Outbound-Mail-Relay-Sender: rfc822; shironeko@aol.example.jp
      def headerlist;  return ['X-AOL-IP']; end

      # Parse bounce messages from Aol Mail
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
        # :from    => %r/\APostmaster [<]Postmaster[@]AOL[.]com[>]\z/,
        # :subject => %r/\AUndeliverable: /,
        return nil unless mhead['x-aol-ip']

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

            if connvalues == connheader.keys.size
              # Final-Recipient: rfc822; kijitora@example.co.jp
              # Original-Recipient: rfc822;kijitora@example.co.jp
              # Action: failed
              # Status: 5.2.2
              # Remote-MTA: dns; mx.example.co.jp
              # Diagnostic-Code: smtp; 550 5.2.2 <kijitora@example.co.jp>... Mailbox Full
              v = dscontents[-1]

              if cv = e.match(/\AFinal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # Final-Recipient: RFC822; userunknown@example.jp
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

              elsif cv = e.match(/\ARemote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Remote-MTA: DNS; mx.example.jp
                v['rhost'] = cv[1].downcase
              else
                # Get error message
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
              # Content-Type: message/delivery-status
              # Content-Transfer-Encoding: 7bit
              #
              # Reporting-MTA: dns; omr-m5.mx.aol.com
              # X-Outbound-Mail-Relay-Queue-ID: CCBA43800007F
              # X-Outbound-Mail-Relay-Sender: rfc822; shironeko@aol.example.jp
              # Arrival-Date: Fri, 21 Nov 2014 17:14:34 -0500 (EST)
              if cv = e.match(/\AReporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Reporting-MTA: dns; mx.example.jp
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
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].gsub(/\\n/, ' '))

          MessagesOf.each_key do |r|
            # Verify each regular expression of session errors
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r.to_s
            break
          end

          if e['status'].empty? || e['status'].end_with?('.0.0')
            # There is no value of Status header or the value is 5.0.0, 4.0.0
            pseudostatus = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['status'] = pseudostatus unless pseudostatus.empty?
          end
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end
    end
  end
end

