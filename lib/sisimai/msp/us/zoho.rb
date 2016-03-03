module Sisimai
  module MSP::US
    # Sisimai::MSP::US::Zoho parses a bounce email which created by Zoho Mail.
    # Methods in the module are called from only Sisimai::Message.
    module Zoho
      # Imported from p5-Sisimail/lib/Sisimai/MSP/US/Zoho.pm
      class << self
        require 'sisimai/msp'
        require 'sisimai/rfc5322'

        Re0 = {
          :'from'     => %r/mailer-daemon[@]mail[.]zoho[.]com\z/,
          :'subject'  => %r{\A(?:
               Undelivered[ ]Mail[ ]Returned[ ]to[ ]Sender
              |Mail[ ]Delivery[ ]Status[ ]Notification
              )
          }x,
          :'x-mailer' => %r/\AZoho Mail\z/,
        }
        Re1 = {
          :begin  => %r/\AThis message was created automatically by mail delivery/,
          :rfc822 => %r/\AReceived:[ \t]*from mail[.]zoho[.]com/,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReFailure = {
          expired: %r/Host not reachable/
        }
        Indicators = Sisimai::MSP.INDICATORS

        def description; return 'Zoho Mail: https://www.zoho.com'; end
        def smtpagent;   return 'US::Zoho'; end

        # X-ZohoMail: Si CHF_MF_NL SS_10 UW48 UB48 FMWL UW48 UB48 SGR3_1_09124_42
        # X-Zoho-Virus-Status: 2
        # X-Mailer: Zoho Mail
        def headerlist;  return ['X-ZohoMail']; end
        def pattern;     return Re0; end

        # Parse bounce messages from Zoho Mail
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
          return nil unless mhead['x-zohomail']

          dscontents = [Sisimai::MSP.DELIVERYSTATUS]
          hasdivided = mbody.split("\n")
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          qprintable = false
          v = nil

          hasdivided.each do |e|
            if readcursor == 0
              # Beginning of the bounce message or delivery status part
              if e =~ Re1[:begin]
                readcursor |= Indicators[:deliverystatus]
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
              if e.empty?
                blanklines += 1
                break if blanklines > 1
                next
              end
              rfc822list << e

            else
              # Before "message/rfc822"
              next if readcursor & Indicators[:deliverystatus] == 0
              next if e.empty?

              # This message was created automatically by mail delivery software.
              # A message that you sent could not be delivered to one or more of its recip=
              # ients. This is a permanent error.=20
              #
              # kijitora@example.co.jp Invalid Address, ERROR_CODE :550, ERROR_CODE :5.1.=
              # 1 <kijitora@example.co.jp>... User Unknown

              # This message was created automatically by mail delivery software.
              # A message that you sent could not be delivered to one or more of its recipients. This is a permanent error.
              #
              # shironeko@example.org Invalid Address, ERROR_CODE :550, ERROR_CODE :Requested action not taken: mailbox unavailable
              v = dscontents[-1]

              if cv = e.match(/\A([^ ]+[@][^ ]+)[ \t]+(.+)\z/)
                # kijitora@example.co.jp Invalid Address, ERROR_CODE :550, ERROR_CODE :5.1.=
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MSP.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                v['diagnosis'] = cv[2]

                if v['diagnosis'] =~ /=\z/
                  # Quoted printable
                  v['diagnosis'] = v['diagnosis'].sub(/=\z/, '')
                  qprintable = true
                end
                recipients += 1

              elsif cv = e.match(/\A\[Status: .+[<]([^ ]+[@][^ ]+)[>],/)
                # Expired
                # [Status: Error, Address: <kijitora@6kaku.example.co.jp>, ResponseCode 421, , Host not reachable.]
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MSP.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                v['diagnosis'] = e
                recipients += 1

              else
                # Continued line
                next unless qprintable
                v['diagnosis'] ||= ''
                v['diagnosis']  += e

              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              %w|lhost rhost|.each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = e['diagnosis'].gsub(/\\n/, ' ')
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            ReFailure.each_key do |r|
              # Verify each regular expression of session errors
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r.to_s
              break
            end

            e['status']  = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['spec']  ||= 'SMTP'
            e['agent']   = Sisimai::MSP::US::Zoho.smtpagent
          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

