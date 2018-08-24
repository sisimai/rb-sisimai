module Sisimai::Bite::Email
  # Sisimai::Bite::Email::SendGrid parses a bounce email which created by
  # SendGrid. Methods in the module are called from only Sisimai::Message.
  module SendGrid
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/SendGrid.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['This is an automatically generated message from SendGrid.'],
        rfc822:  ['Content-Type: message/rfc822'],
      }.freeze

      def description; return 'SendGrid: http://sendgrid.com/'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end

      # Return-Path: <apps@sendgrid.net>
      # X-Mailer: MIME-tools 5.502 (Entity 5.502)
      def headerlist;  return ['Return-Path', 'X-Mailer']; end

      # Parse bounce messages from SendGrid
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
        # :'from'        => %r/\AMAILER-DAEMON\z/,
        return nil unless mhead['return-path']
        return nil unless mhead['return-path'] == '<apps@sendgrid.net>'
        return nil unless mhead['subject'] == 'Undelivered Mail Returned to Sender'

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
          'date' => '',     # The value of Arrival-Date header
        }
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

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
              # Final-Recipient: rfc822; kijitora@example.jp
              # Original-Recipient: rfc822; kijitora@example.jp
              # Action: failed
              # Status: 5.1.1
              # Diagnostic-Code: 550 5.1.1 <kijitora@example.jp>... User Unknown
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
                # Status: 5.1.1
                # Status:5.2.0
                # Status: 5.1.0 (permanent failure)
                v['status'] = cv[1]

              else
                if cv = e.match(/\ADiagnostic-Code:[ ]*(.+)\z/)
                  # Diagnostic-Code: 550 5.1.1 <userunknown@example.jp>... User Unknown
                  v['diagnosis'] = cv[1]

                elsif p.start_with?('Diagnostic-Code:') && cv = e.match(/\A[ \t]+(.+)\z/)
                  # Continued line of the value of Diagnostic-Code header
                  v['diagnosis'] << ' ' << cv[1]
                  havepassed[-1] = 'Diagnostic-Code: ' << e
                end
              end
            else
              # This is an automatically generated message from SendGrid.
              #
              # I'm sorry to have to tell you that your message was not able to be
              # delivered to one of its intended recipients.
              #
              # If you require assistance with this, please contact SendGrid support.
              #
              # shironekochan:000000:<kijitora@example.jp> : 192.0.2.250 : mx.example.jp:[192.0.2.153] :
              #   550 5.1.1 <userunknown@cubicroot.jp>... User Unknown  in RCPT TO
              #
              # ------------=_1351676802-30315-116783
              # Content-Type: message/delivery-status
              # Content-Disposition: inline
              # Content-Transfer-Encoding: 7bit
              # Content-Description: Delivery Report
              #
              # X-SendGrid-QueueID: 959479146
              # X-SendGrid-Sender: <bounces+61689-10be-kijitora=example.jp@sendgrid.info>
              # Arrival-Date: 2012-12-31 23-59-59
              if cv = e.match(/.+ in (?:End of )?([A-Z]{4}).*\z/)
                # in RCPT TO, in MAIL FROM, end of DATA
                commandtxt = cv[1]

              elsif cv = e.match(/\AArrival-Date:[ ]*(.+)\z/)
                # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                next unless connheader['date'].empty?
                arrivaldate = cv[1]

                if cv = e.match(/\AArrival-Date: (\d{4})[-](\d{2})[-](\d{2}) (\d{2})[-](\d{2})[-](\d{2})\z/)
                  # Arrival-Date: 2011-08-12 01-05-05
                  arrivaldate << 'Thu, ' << cv[3] + ' '
                  arrivaldate << Sisimai::DateTime.monthname(0)[cv[2].to_i - 1]
                  arrivaldate << ' ' << cv[1] + ' ' << [cv[4], cv[5], cv[6]].join(':')
                  arrivaldate << ' ' << Sisimai::DateTime.abbr2tz('CDT')
                end
                connheader['date'] = arrivaldate
                connvalues += 1
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          # Get the value of SMTP status code as a pseudo D.S.N.
          if cv = e['diagnosis'].match(/\b([45])\d\d[ \t]*/)
            # 4xx or 5xx
            e['status'] = cv[1] + '.0.0'
          end

          if e['status'] == '5.0.0' || e['status'] == '4.0.0'
            # Get the value of D.S.N. from the error message or the value of
            # Diagnostic-Code header.
            pseudostatus = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['status'] = pseudostatus unless pseudostatus.empty?
          end

          if e['action'] == 'expired'
            # Action: expired
            e['reason'] = 'expired'
            if !e['status'] || e['status'].end_with?('.0.0')
              # Set pseudo Status code value if the value of Status is not
              # defined or 4.0.0 or 5.0.0.
              pseudostatus = Sisimai::SMTP::Status.code('expired')
              e['status']  = pseudostatus unless pseudostatus.empty?
            end
          end

          e['agent']   = self.smtpagent
          e['command'] = commandtxt
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

