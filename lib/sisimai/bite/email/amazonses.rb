module Sisimai::Bite::Email
  # Sisimai::Bite::Email::AmazonSES parses a bounce email which created by
  # Amazon Simple Email Service.
  # Methods in the module are called from only Sisimai::Message.
  module AmazonSES
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/AmazonSES.pm
      require 'sisimai/bite/email'

      # http://aws.amazon.com/ses/
      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['The following message to <', 'An error occurred while trying to deliver the mail'],
        rfc822:  ['content-type: message/rfc822'],
      }.freeze
      MessagesOf = { expired: ['Delivery expired'] }.freeze

      def description; return 'Amazon SES(Sending): http://aws.amazon.com/ses/'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end

      # X-SenderID: Sendmail Sender-ID Filter v1.0.0 nijo.example.jp p7V3i843003008
      # X-Original-To: 000001321defbd2a-788e31c8-2be1-422f-a8d4-cf7765cc9ed7-000000@email-bounces.amazonses.com
      # X-AWS-Outgoing: 199.255.192.156
      # X-SES-Outgoing: 2016.10.12-54.240.27.6
      def headerlist;  return ['X-AWS-Outgoing', 'X-SES-Outgoing', 'x-amz-sns-message-id']; end

      # Parse bounce messages from Amazon SES
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
        # :from    => %r/\AMAILER-DAEMON[@]email[-]bounces[.]amazonses[.]com\z/,
        # :subject => %r/\ADelivery Status Notification [(]Failure[)]\z/,
        return nil if mhead['x-mailer'].to_s.start_with?('Amazon WorkMail')

        match  = 0
        match += 1 if mhead['x-aws-outgoing']
        match += 1 if mhead['x-ses-outgoing']
        return nil unless match > 0

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        connvalues = 0      # (Integer) Flag, 1 if all the value of connheader have been set
        connheader = {
          'lhost' => '',    # The value of Reporting-MTA header
        }
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e.start_with?(StartingOf[:message][0], StartingOf[:message][1])
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
              # Final-Recipient: rfc822;kijitora@example.jp
              # Action: failed
              # Status: 5.0.0 (permanent failure)
              # Remote-MTA: dns; [192.0.2.9]
              # Diagnostic-Code: smtp; 5.1.0 - Unknown address error 550-'5.7.1
              #  <000001321defbd2a-788e31c8-2be1-422f-a8d4-cf7765cc9ed7-000000@email-bounces.amazonses.com>...
              #  Access denied' (delivery attempts: 0)
              #
              # --JuU8e.4gyIcCrxq.1RFbQY.3Vu7Hs+
              # content-type: message/rfc822
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
                v['rhost'] = cv[1].downcase

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
              # The following message to <kijitora@example.jp> was undeliverable.
              # The reason for the problem:
              # 5.1.0 - Unknown address error 550-'5.7.1 <0000000000000000-00000000-0000-00=
              # 00-0000-000000000000-000000@email-bounces.amazonses.com>... Access denied'
              #
              # --JuU8e.4gyIcCrxq.1RFbQY.3Vu7Hs+
              # content-type: message/delivery-status
              #
              # Reporting-MTA: dns; a192-79.smtp-out.amazonses.com
              #
              if cv = e.match(/\AReporting-MTA:[ ]*[DNSdns]+;[ ]*(.+)\z/)
                # Reporting-MTA: dns; mx.example.jp
                next unless connheader['lhost'].empty?
                connheader['lhost'] = cv[1].downcase
                connvalues += 1
              end

            end
          end
        end

        if recipients == 0 && mbody =~ /notificationType/
          # Try to parse with Sisimai::Bite::JSON::AmazonSES module
          require 'sisimai/bite/json/amazonses'
          j = Sisimai::Bite::JSON::AmazonSES.scan(mhead, mbody)

          if j['ds'].is_a? Array
            # Update dscontents
            dscontents = j['ds']
            recipients = j['ds'].size
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          connheader.each_key { |a| e[a] ||= connheader[a] || '' }

          e['agent'] = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].to_s.gsub(/\\n/, ' '))

          if e['status'].to_s.start_with?('5.0.0', '5.1.0', '4.0.0', '4.1.0')
            # Get other D.S.N. value from the error message
            errormessage = e['diagnosis']

            # 5.1.0 - Unknown address error 550-'5.7.1 ...
            if cv = e['diagnosis'].match(/["'](\d[.]\d[.]\d.+)['"]/) then errormessage = cv[1] end
            pseudostatus = Sisimai::SMTP::Status.find(errormessage)
            e['status'] = pseudostatus unless pseudostatus.empty?
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

