module Sisimai
  module MSP::US
    # Sisimai::MSP::US::AmazonSES parses a bounce email which created by Amazon
    # Simple Email Service.
    # Methods in the module are called from only Sisimai::Message.
    module AmazonSES
      # Imported from p5-Sisimail/lib/Sisimai/MSP/US/AmazonSES.pm
      class << self
        require 'sisimai/msp'
        require 'sisimai/rfc5322'

        # http://aws.amazon.com/ses/
        Re0 = {
          :from    => %r/\AMAILER-DAEMON[@]email[-]bounces[.]amazonses[.]com\z/,
          :subject => %r/\ADelivery Status Notification [(]Failure[)]\z/,
        }
        Re1 = {
          :begin   => %r/\AThe following message to [<]/,
          :rfc822  => %r|\Acontent-type: message/rfc822\z|,
          :endof   => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReFailure = {
          expired: %r/Delivery[ ]expired/x,
        }
        Indicators = Sisimai::MSP.INDICATORS

        def description; return 'Amazon SES(Sending): http://aws.amazon.com/ses/'; end
        def smtpagent;   return 'US::AmazonSES'; end

        # X-SenderID: Sendmail Sender-ID Filter v1.0.0 nijo.example.jp p7V3i843003008
        # X-Original-To: 000001321defbd2a-788e31c8-2be1-422f-a8d4-cf7765cc9ed7-000000@email-bounces.amazonses.com
        # X-AWS-Outgoing: 199.255.192.156
        def headerlist;  return ['X-AWS-Outgoing']; end
        def pattern;     return Re0; end

        # Parse bounce messages from Amazon SES
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
          return nil unless mhead['x-aws-outgoing']

          dscontents = [Sisimai::MSP.DELIVERYSTATUS]
          hasdivided = mbody.split("\n")
          havepassed = ['']
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          connvalues = 0      # (Integer) Flag, 1 if all the value of $connheader have been set
          connheader = {
            'lhost' => '',    # The value of Reporting-MTA header
          }
          v = nil

          hasdivided.each do |e|
            # Save the current line for the next loop
            havepassed << e
            p = havepassed[-2]

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
              # After "message/rfc822"
              if e.empty?
                blanklines += 1
                break if blanklines > 1
                next
              end
              rfc822list << e

            else
              # Before "message/rfc822"
              next if readcursor & Indicators[:'deliverystatus'] == 0
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

                if cv = e.match(/\A[Ff]inal-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                  # Final-Recipient: RFC822; userunknown@example.jp
                  if v['recipient']
                    # There are multiple recipient addresses in the message body.
                    dscontents << Sisimai::MSP.DELIVERYSTATUS
                    v = dscontents[-1]
                  end
                  v['recipient'] = cv[1]
                  recipients += 1

                elsif cv = e.match(/\A[Xx]-[Aa]ctual-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                  # X-Actual-Recipient: RFC822; kijitora@example.co.jp
                  v['alias'] = cv[1]

                elsif cv = e.match(/\A[Aa]ction:[ ]*(.+)\z/)
                  # Action: failed
                  v['action'] = cv[1].downcase

                elsif cv = e.match(/\A[Ss]tatus:[ ]*(\d[.]\d+[.]\d+)/)
                  # Status: 5.1.1
                  # Status:5.2.0
                  # Status: 5.1.0 (permanent failure)
                  v['status'] = cv[1]
                  v['softbounce'] = 0 if e =~ /[(]permanent failure[)]/

                elsif cv = e.match(/\A[Rr]emote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Remote-MTA: DNS; mx.example.jp
                  v['rhost'] = cv[1].downcase

                elsif cv = e.match(/\A[Ll]ast-[Aa]ttempt-[Dd]ate:[ ]*(.+)\z/)
                  # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
                  v['date'] = cv[1]

                else
                  if cv = e.match(/\A[Dd]iagnostic-[Cc]ode:[ ]*(.+?);[ ]*(.+)\z/)
                    # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                    v['spec'] = cv[1].upcase
                    v['diagnosis'] = cv[2]

                  elsif p =~ /\A[Dd]iagnostic-[Cc]ode:[ ]*/ && cv = e.match(/\A[ \t]+(.+)\z/)
                    # Continued line of the value of Diagnostic-Code header
                    v['diagnosis'] ||= ''
                    v['diagnosis']  += ' ' + cv[1]
                    havepassed[-1] = 'Diagnostic-Code: ' + e
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
                if cv = e.match(/\A[Rr]eporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Reporting-MTA: dns; mx.example.jp
                  next if connheader['lhost'].size > 0
                  connheader['lhost'] = cv[1].downcase
                  connvalues += 1
                end

              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            # Set default values if each value is empty.
            connheader.each_key { |a| e[a] ||= connheader[a] || '' }

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              %w|lhost rhost|.each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = e['diagnosis'].gsub(/\\n/, ' ')
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            if e['status'] =~ /\A[45][.][01][.]0\z/
              # Get other D.S.N. value from the error message
              errormessage = e['diagnosis']

              if cv = e['diagnosis'].match(/["'](\d[.]\d[.]\d.+)['"]/)
                # 5.1.0 - Unknown address error 550-'5.7.1 ...
                errormessage = cv[1]
              end

              pseudostatus = Sisimai::SMTP::Status.find(errormessage)
              e['status'] = pseudostatus if pseudostatus.size > 0
            end

            ReFailure.each_key do |r|
              # Verify each regular expression of session errors
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r.to_s
              break
            end

            e['reason'] ||= Sisimai::SMTP::Status.name(e['status'])
            e['spec']  ||= 'SMTP'
            e['agent']   = Sisimai::MSP::US::AmazonSES.smtpagent
          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

