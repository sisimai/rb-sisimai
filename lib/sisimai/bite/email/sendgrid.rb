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

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        commandtxt = ''     # (String) SMTP Command name begin with the string '>>>'
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            if e == StartingOf[:message][0]
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part(message/rfc822)
            if e == StartingOf[:rfc822][0]
              readcursor |= Indicators[:'message-rfc822']
              next
            end
          end

          if readcursor & Indicators[:'message-rfc822'] > 0
            # message/rfc822 OR text/rfc822-headers part
            if e.empty?
              blanklines += 1
              break if blanklines > 1
              next
            end
            rfc822list << e
          else
            # message/delivery-status part
            next if (readcursor & Indicators[:deliverystatus]) == 0
            next if e.empty?

            if f = Sisimai::RFC1894.match(e)
              # "e" matched with any field defined in RFC3464
              o = Sisimai::RFC1894.field(e)
              v = dscontents[-1]

              unless o
                # Fallback code for empty value or invalid formatted value
                # - Status: (empty)
                # - Diagnostic-Code: 550 5.1.1 ... (No "diagnostic-type" sub field)
                next unless cv = e.match(/\ADiagnostic-Code:[ ]*(.+)/)
                v['diagnosis'] = cv[1]
                next;
              end

              if o[-1] == 'addr'
                # Final-Recipient: rfc822; kijitora@example.jp
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                if o[0] == 'final-recipient'
                  # Final-Recipient: rfc822; kijitora@example.jp
                  if v['recipient']
                    # There are multiple recipient addresses in the message body.
                    dscontents << Sisimai::Bite.DELIVERYSTATUS
                    v = dscontents[-1]
                  end
                  v['recipient'] = o[2]
                  recipients += 1
                else
                  # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                  v['alias'] = o[2]
                end
              elsif o[-1] == 'code'
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                v['spec'] = o[1]
                v['diagnosis'] = o[2]
              elsif o[-1] == 'date'
                # Arrival-Date: 2012-12-31 23-59-59
                next unless cv = e.match(/\AArrival-Date: (\d{4})[-](\d{2})[-](\d{2}) (\d{2})[-](\d{2})[-](\d{2})\z/)
                o[1] << 'Thu, ' << cv[3] + ' '
                o[1] << Sisimai::DateTime.monthname(0)[cv[2].to_i - 1]
                o[1] << ' ' << cv[1] + ' ' << [cv[4], cv[5], cv[6]].join(':')
                o[1] << ' ' << Sisimai::DateTime.abbr2tz('CDT')
              else
                # Other DSN fields defined in RFC3464
                next unless fieldtable.key?(o[0].to_sym)
                v[fieldtable[o[0].to_sym]] = o[2]

                next unless f == 1
                permessage[fieldtable[o[0].to_sym]] = o[2]
              end
            else
              # The line does not begin with a DSN field defined in RFC3464
              if cv = e.match(/.+ in (?:End of )?([A-Z]{4}).*\z/)
                # in RCPT TO, in MAIL FROM, end of DATA
                commandtxt = cv[1]
              else
                # Continued line of the value of Diagnostic-Code field
                next unless p.start_with?('Diagnostic-Code:')
                next unless cv = e.match(/\A[ \t]+(.+)\z/)
                v['diagnosis'] << ' ' << cv[1]
                havepassed[-1] = 'Diagnostic-Code: ' << e
              end
            end
          end # End of message/delivery-status
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Get the value of SMTP status code as a pseudo D.S.N.
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
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

          e['lhost'] ||= permessage['rhost']
          e['agent']   = self.smtpagent
          e['command'] = commandtxt
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

