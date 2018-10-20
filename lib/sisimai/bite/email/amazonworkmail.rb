module Sisimai::Bite::Email
  # Sisimai::Bite::Email::AmazonWorkMail parses a bounce email which created by
  # Amazon WorkMail. Methods in the module are called from only Sisimai::Message.
  module AmazonWorkMail
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/AmazonWorkMail.pm
      require 'sisimai/bite/email'

      # https://aws.amazon.com/workmail/
      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['Technical report:'],
        rfc822:  ['content-type: message/rfc822'],
      }.freeze

      def description; return 'Amazon WorkMail: https://aws.amazon.com/workmail/'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end

      # X-Mailer: Amazon WorkMail
      # X-Original-Mailer: Amazon WorkMail
      # X-Ses-Outgoing: 2016.01.14-54.240.27.159
      def headerlist;  return ['X-SES-Outgoing', 'X-Original-Mailer']; end

      # Parse bounce messages from Amazon WorkMail
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
        # :'subject'  => %r/Delivery[_ ]Status[_ ]Notification[_ ].+Failure/,
        # :'received' => %r/.+[.]smtp-out[.].+[.]amazonses[.]com\b/,
        # :'x-mailer' => %r/\AAmazon WorkMail\z/,
        match = 0
        xmail = mhead['x-original-mailer'] || mhead['x-mailer'] || ''

        match += 1 if mhead['x-ses-outgoing']
        unless xmail.empty?
          # X-Mailer: Amazon WorkMail
          # X-Original-Mailer: Amazon WorkMail
          match += 1 if xmail == 'Amazon WorkMail'
        end
        return nil if match < 2

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
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

            if connvalues == connheader.keys.size
              # Action: failed
              # Final-Recipient: rfc822; kijitora@libsisimai.org
              # Diagnostic-Code: smtp; 554 4.4.7 Message expired: unable to deliver in 840 minutes.<421 4.4.2 Connection timed out>
              # Status: 4.4.7
              v = dscontents[-1]

              if cv = e.match(/\AFinal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # Final-Recipient: RFC822; kijitora@example.jp
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
                # Status: 5.1.1
                v['status'] = cv[1]
              else
                if cv = e.match(/\ADiagnostic-Code:[ ]*(.+?);[ ]*(.+)\z/)
                  # Diagnostic-Code: SMTP; 550 5.1.1 <kijitora@example.jp>... User Unknown
                  v['spec'] = cv[1].upcase
                  v['diagnosis'] = cv[2]
                end
              end
            else
              # Technical report:
              #
              # Reporting-MTA: dsn; a27-85.smtp-out.us-west-2.amazonses.com
              #
              if cv = e.match(/\AReporting-MTA:[ ]*[DNSdns]+;[ ]*(.+)\z/)
                # Reporting-MTA: dns; mx.example.jp
                next unless connheader['lhost'].empty?
                connheader['lhost'] = cv[1].downcase
                connvalues += 1
              end
            end

            # <!DOCTYPE HTML><html>
            # <head>
            # <meta name="Generator" content="Amazon WorkMail v3.0-2023.77">
            # <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
            break if e.start_with?('<!DOCTYPE HTML><html>')
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          connheader.each_key { |a| e[a] ||= connheader[a] || '' }

          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          if e['status'].to_s.start_with?('5.0.0', '5.1.0', '4.0.0', '4.1.0')
            # Get other D.S.N. value from the error message
            errormessage = e['diagnosis']

            # 5.1.0 - Unknown address error 550-'5.7.1 ...
            if cv = e['diagnosis'].match(/["'](\d[.]\d[.]\d.+)['"]/) then errormessage = cv[1] end

            pseudostatus = Sisimai::SMTP::Status.find(errormessage)
            e['status'] = pseudostatus unless pseudostatus.empty?
          end

          # 554 4.4.7 Message expired: unable to deliver in 840 minutes.
          # <421 4.4.2 Connection timed out>
          if cv = e['diagnosis'].match(/[<]([245]\d\d)[ ].+[>]/) then e['replycode'] = cv[1] end

          e['reason'] ||= Sisimai::SMTP::Status.name(e['status'])
          e['agent']    = self.smtpagent
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

