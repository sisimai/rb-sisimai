module Sisimai::Bite::Email
  # Sisimai::Bite::Email::MessageLabs parses a bounce email which created by
  # Symantec.cloud: formerly MessageLabs. Methods in the module are called
  # from only Sisimai::Message.
  module MessageLabs
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/MessageLabs.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['Content-Type: message/delivery-status'],
        rfc822:  ['Content-Type: text/rfc822-headers'],
      }.freeze
      ReFailures = {
        userunknown:   %r/(?:542 .+ Rejected|No such user)/,
        securityerror: %r/Please turn on SMTP Authentication in your mail client/,
      }.freeze

      def description; return 'Symantec.cloud http://www.messagelabs.com'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end

      # X-Msg-Ref: server-11.tower-143.messagelabs.com!1419367175!36473369!1
      # X-Originating-IP: [10.245.230.38]
      # X-StarScan-Received:
      # X-StarScan-Version: 6.12.5; banners=-,-,-
      # X-VirusChecked: Checked
      def headerlist;  return ['X-Msg-Ref']; end

      # Parse bounce messages from Symantec.cloud(MessageLabs)
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
        return nil unless mhead['x-msg-ref']
        return nil unless mhead['from'].include?('MAILER-DAEMON@messagelabs.com')
        return nil unless mhead['subject'].start_with?('Mail Delivery Failure')

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        commandset = []     # (Array) ``in reply to * command'' list
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
              # This is the mail delivery agent at messagelabs.com.
              #
              # I was unable to deliver your message to the following addresses:
              #
              # maria@dest.example.net
              #
              # Reason: 550 maria@dest.example.net... No such user
              #
              # The message subject was: Re: BOAS FESTAS!
              # The message date was: Tue, 23 Dec 2014 20:39:24 +0000
              # The message identifier was: DB/3F-17375-60D39495
              # The message reference was: server-5.tower-143.messagelabs.com!1419367172!32=
              # 691968!1
              #
              # Please do not reply to this email as it is sent from an unattended mailbox.
              # Please visit www.messagelabs.com/support for more details
              # about this error message and instructions to resolve this issue.
              #
              #
              # --b0Nvs+XKfKLLRaP/Qo8jZhQPoiqeWi3KWPXMgw==
              # Content-Type: message/delivery-status
              #
              # Reporting-MTA: dns; server-15.bemta-3.messagelabs.com
              # Arrival-Date: Tue, 23 Dec 2014 20:39:34 +0000
              #
              # Action: failed
              # Status: 5.0.0
              # Last-Attempt-Date: Tue, 23 Dec 2014 20:39:35 +0000
              # Remote-MTA: dns; mail.dest.example.net
              # Diagnostic-Code: smtp; 550 maria@dest.example.net... No such user
              # Final-Recipient: rfc822; maria@dest.example.net
              v = dscontents[-1]

              if cv = e.match(/\AFinal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # Final-Recipient: rfc822; maria@dest.example.net
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
                # Status: 5.0.0
                v['status'] = cv[1]
              else
                if cv = e.match(/\ADiagnostic-Code:[ ]*(.+?);[ ]*(.+)\z/)
                  # Diagnostic-Code: smtp; 550 maria@dest.example.net... No such user
                  v['spec'] = cv[1].upcase
                  v['diagnosis'] = cv[2]

                elsif p.start_with?('Diagnostic-Code:') && cv = e.match(/\A[ \t]+(.+)\z/)
                  # Continued line of the value of Diagnostic-Code header
                  v['diagnosis'] << ' ' << cv[1]
                  havepassed[-1] = 'Diagnostic-Code: ' << e
                end
              end
            else
              # Reporting-MTA: dns; server-15.bemta-3.messagelabs.com
              # Arrival-Date: Tue, 23 Dec 2014 20:39:34 +0000
              if cv = e.match(/\AReporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Reporting-MTA: dns; server-15.bemta-3.messagelabs.com
                next unless connheader['lhost'].empty?
                connheader['lhost'] = cv[1].downcase
                connvalues += 1

              elsif cv = e.match(/\AArrival-Date:[ ]*(.+)\z/)
                # Arrival-Date: Tue, 23 Dec 2014 20:39:34 +0000
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
          e['command']   = commandset.shift || ''
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          ReFailures.each_key do |r|
            # Verify each regular expression of session errors
            next unless e['diagnosis'] =~ ReFailures[r]
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

