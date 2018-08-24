module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Courier parses a bounce email which created by Courier
  # MTA. Methods in the module are called from only Sisimai::Message.
  module Courier
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Courier.pm
      require 'sisimai/bite/email'

      # http://www.courier-mta.org/courierdsn.html
      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        # courier/module.dsn/dsn*.txt
        message: ['DELAYS IN DELIVERING YOUR MESSAGE', 'UNDELIVERABLE MAIL'],
        rfc822:  ['Content-Type: message/rfc822', 'Content-Type: text/rfc822-headers'],
      }.freeze

      MessagesOf = {
        # courier/module.esmtp/esmtpclient.c:526| hard_error(del, ctf, "No such domain.");
        hostunknown: ['No such domain.'],
        # courier/module.esmtp/esmtpclient.c:531| hard_error(del, ctf,
        # courier/module.esmtp/esmtpclient.c:532|  "This domain's DNS violates RFC 1035.");
        systemerror: ["This domain's DNS violates RFC 1035."],
        # courier/module.esmtp/esmtpclient.c:535| soft_error(del, ctf, "DNS lookup failed.");
        networkerror: ['DNS lookup failed.'],
      }.freeze

      def description; return 'Courier MTA'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Courier MTA
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
        match  = 0
        match += 1 if mhead['from'].include?('Courier mail server at ')
        match += 1 if mhead['subject'] =~ /(?:NOTICE: mail delivery status[.]|WARNING: delayed mail[.])/
        if mhead['message-id']
          # Message-ID: <courier.4D025E3A.00001792@5jo.example.org>
          match += 1 if mhead['message-id'] =~ /\A[<]courier[.][0-9A-F]+[.]/
        end
        return nil unless match > 0

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        commandtxt = ''     # (String) SMTP Command name begin with the string '>>>'
        connvalues = 0      # (Integer) Flag, 1 if all the value of connheader have been set
        connheader = {
          'date'  => '',    # The value of Arrival-Date header
          'rhost' => '',    # The value of Reporting-MTA header
          'lhost' => '',    # The value of Received-From-MTA header
        }
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e.include?(StartingOf[:message][0]) || e.include?(StartingOf[:message][1])
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e.start_with?(StartingOf[:rfc822][0], StartingOf[:rfc822][1])
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
              # Action: failed
              # Status: 5.0.0
              # Remote-MTA: dns; mx.example.co.jp [192.0.2.95]
              # Diagnostic-Code: smtp; 550 5.1.1 <kijitora@example.co.jp>... User Unknown
              v = dscontents[-1]

              if cv = e.match(/\AFinal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # Final-Recipient: rfc822; kijitora@example.co.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Bite.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              elsif cv = e.match(/\AX-Actual-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # X-Actual-Recipient: RFC822; kijitora@example.co.jp
                v['alias'] = cv[1]

              elsif cv = e.match(/\AAction:[ ]*(.+)\z/)
                # Action: failed
                v['action'] = cv[1].downcase

              elsif cv = e.match(/\AStatus:[ ]*(\d[.]\d+[.]\d+)/)
                # Status: 5.1.1
                # Status:5.2.0
                # Status: 5.1.0 (permanent failure)
                v['status'] = cv[1]

              elsif cv = e.match(/\ARemote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Remote-MTA: DNS; mx.example.jp
                # Get the first element
                v['rhost'] = cv[1].downcase
                v['rhost'] = v['rhost'].split(' ').shift if v['rhost'].include?(' ')

              elsif cv = e.match(/\ALast-Attempt-Date:[ ]*(.+)\z/)
                # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
                v['date'] = cv[1]
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
              # This is a delivery status notification from marutamachi.example.org,
              # running the Courier mail server, version 0.65.2.
              #
              # The original message was received on Sat, 11 Dec 2010 12:19:57 +0900
              # from [127.0.0.1] (c10920.example.com [192.0.2.20])
              #
              # ---------------------------------------------------------------------------
              #
              #                           UNDELIVERABLE MAIL
              #
              # Your message to the following recipients cannot be delivered:
              #
              # <kijitora@example.co.jp>:
              #    mx.example.co.jp [74.207.247.95]:
              # >>> RCPT TO:<kijitora@example.co.jp>
              # <<< 550 5.1.1 <kijitora@example.co.jp>... User Unknown
              #
              # ---------------------------------------------------------------------------
              if cv = e.match(/\A[>]{3}[ ]+([A-Z]{4})[ ]?/)
                # >>> DATA
                next unless commandtxt.empty?
                commandtxt = cv[1]

              elsif cv = e.match(/\AReporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Reporting-MTA: dns; mx.example.jp
                next unless connheader['rhost'].empty?
                connheader['rhost'] = cv[1].downcase
                connvalues += 1

              elsif cv = e.match(/\AReceived-From-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Received-From-MTA: DNS; x1x2x3x4.dhcp.example.ne.jp
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
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          MessagesOf.each_key do |r|
            # Verify each regular expression of session errors
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r.to_s
            break
          end

          e['agent']     = self.smtpagent
          e['command'] ||= commandtxt || ''
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

