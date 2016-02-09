module Sisimai
  module MSP::US
    # Sisimai::MSP::US::SendGrid parses a bounce email which created by SendGrid.
    # Methods in the module are called from only Sisimai::Message.
    module SendGrid
      # Imported from p5-Sisimail/lib/Sisimai/MSP/US/SendGrid.pm
      class << self
        require 'sisimai/msp'
        require 'sisimai/rfc5322'

        Re0 = {
          :'from'        => %r/\AMAILER-DAEMON\z/,
          :'return-path' => %r/\A[<]apps[@]sendgrid[.]net[>]\z/,
          :'subject'     => %r/\AUndelivered Mail Returned to Sender\z/,
        }
        Re1 = {
          :begin  => %r/\AThis is an automatically generated message from SendGrid[.]\z/,
          :error  => %r/\AIf you require assistance with this, please contact SendGrid support[.]\z/,
          :rfc822 => %r|\AContent-Type: message/rfc822|,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        Indicators = Sisimai::MSP.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'SendGrid: http://sendgrid.com/'; end
        def smtpagent;   return 'US::SendGrid'; end

        # Return-Path: <apps@sendgrid.net>
        # X-Mailer: MIME-tools 5.502 (Entity 5.502)
        def headerlist;  return ['Return-Path', 'X-Mailer']; end
        def pattern;     return Re0; end

        # Parse bounce messages from SendGrid
        # @param         [Hash] mhead       Message header of a bounce email
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
          return nil unless mhead
          return nil unless mbody
          return nil unless mhead['return-path']
          return nil unless mhead['return-path'] =~ Re0[:'return-path']
          return nil unless mhead['subject']     =~ Re0[:'subject']

          require 'sisimai/datetime'
          dscontents = []; dscontents << Sisimai::MSP.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          havepassed = ['']
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          commandtxt = ''     # (String) SMTP Command name begin with the string '>>>'
          connvalues = 0      # (Integer) Flag, 1 if all the value of $connheader have been set
          connheader = {
            'date' => '',     # The value of Arrival-Date header
          }
          v = nil

          hasdivided.each do |e|
            # Save the current line for the next loop
            havepassed << e; p = havepassed[-2]

            if readcursor == 0
              # Beginning of the bounce message or delivery status part
              if e =~ Re1[:begin]
                readcursor |= Indicators[:'deliverystatus']
                next
              end
            end

            if readcursor & Indicators[:'message-rfc822'] == 0
              # Beginning of the original message part
              if e =~ Re1[:rfc822]
                readcursor |= Indicators[:'message-rfc822']
                next
              end
            end

            if readcursor & Indicators[:'message-rfc822'] > 0
              # After "message/rfc822"
              if cv = e.match(/\A([-0-9A-Za-z]+?)[:][ ]*.+\z/)
                # Get required headers only
                lhs = cv[1].downcase
                previousfn = ''
                next unless RFC822Head.key?(lhs)

                previousfn  = lhs
                rfc822part += e + "\n"

              elsif e =~ /\A[ \t]+/
                # Continued line from the previous line
                next if rfc822next[previousfn]
                rfc822part += e + "\n" if LongFields.key?(previousfn)

              else
                # Check the end of headers in rfc822 part
                next unless LongFields.key?(previousfn)
                next unless e.empty?
                rfc822next[previousfn] = true
              end

            else
              # Before "message/rfc822"
              next if readcursor & Indicators[:'deliverystatus'] == 0
              next if e.empty?

              if connvalues == connheader.keys.size
                # Final-Recipient: rfc822; kijitora@example.jp
                # Original-Recipient: rfc822; kijitora@example.jp
                # Action: failed
                # Status: 5.1.1
                # Diagnostic-Code: 550 5.1.1 <kijitora@example.jp>... User Unknown
                v = dscontents[-1]

                if cv = e.match(/\A[Ff]inal-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                  # Final-Recipient: RFC822; userunknown@example.jp
                  if v['recipient']
                    # There are multiple recipient addresses in the message body.
                    dscontents << Sisimai::MSP.DELIVERYSTATUS
                    v = dscontents[-1]
                  end
                  v['recipient'] = cv[1]
                  recipients += 1

                elsif cv = e.match(/\A[Aa]ction:[ ]*(.+)\z/)
                  # Action: failed
                  v['action'] = cv[1].downcase

                elsif cv = e.match(/\A[Ss]tatus:[ ]*(\d[.]\d+[.]\d+)/)
                  # Status: 5.1.1
                  # Status:5.2.0
                  # Status: 5.1.0 (permanent failure)
                  v['status'] = cv[1]

                else
                  if cv = e.match(/\A[Dd]iagnostic-[Cc]ode:[ ]*(.+)\z/)
                    # Diagnostic-Code: 550 5.1.1 <userunknown@example.jp>... User Unknown
                    v['diagnosis'] = cv[1]

                  elsif p =~ /\A[Dd]iagnostic-[Cc]ode:[ ]*/ && cv = e.match(/\A[ \t]+(.+)\z/)
                    # Continued line of the value of Diagnostic-Code header
                    v['diagnosis'] ||= ''
                    v['diagnosis']  += ' ' + cv[1]
                    havepassed[-1] = 'Diagnostic-Code: ' + e
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

                elsif cv = e.match(/\A[Aa]rrival-[Dd]ate:[ ]*(.+)\z/)
                  # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                  next if connheader['date'].size > 0
                  arrivaldate = cv[1]

                  if cv = e.match(/\A[Aa]rrival-[Dd]ate: (\d{4})[-](\d{2})[-](\d{2}) (\d{2})[-](\d{2})[-](\d{2})\z/)
                    # Arrival-Date: 2011-08-12 01-05-05
                    arrivaldate += 'Thu, ' + cv[3] + ' '
                    arrivaldate += Sisimai::DateTime.monthname(0)[cv[2].to_i - 1]
                    arrivaldate += ' ' + cv[1] + ' ' + [cv[4], cv[5], cv[6]].join(':')
                    arrivaldate += ' ' + Sisimai::DateTime.abbr2tz('CDT')
                  end
                  connheader['date'] = arrivaldate
                  connvalues += 1
                end
              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            if e['status']
              # Check softbounce or not
              e['softbounce'] = 1 if e['status'] =~ /\A4[.]/

            else
              # Get the value of SMTP status code as a pseudo D.S.N.
              if cv = e['diagnosis'].match(/\b([45])\d\d[ \t]*/)
                # 4xx or 5xx
                e['softbounce'] = 1 if cv[1].to_i == 4
                e['status'] = sprintf("%d.0.0", cv[1])
              end
            end

            if e['status'] =~ /[45][.]0[.]0/
              # Get the value of D.S.N. from the error message or the value of
              # Diagnostic-Code header.
              pseudostatus = Sisimai::SMTP::Status.find(e['diagnosis'])
              e['status'] = pseudostatus if pseudostatus.size > 0
            end

            if e['action'] == 'expired'
              # Action: expired
              e['reason'] = 'expired'
              if !e['status'] || e['status'] =~ /[45][.]0[.]0/
                # Set pseudo Status code value if the value of Status is not
                # defined or 4.0.0 or 5.0.0.
                pseudostatus = Sisimai::SMTP::Status.code('expired')
                e['status']  = pseudostatus if pseudostatus.size > 0
              end
            end

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              %w|lhost rhost|.each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end

            e['spec']  ||= 'SMTP'
            e['agent']   = Sisimai::MSP::US::SendGrid.smtpagent
            e['command'] = commandtxt
          end

          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

