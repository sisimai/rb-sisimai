module Sisimai
  module MSP::US
    # Sisimai::MSP::US::Yahoo parses a bounce email which created by Yahoo! MAIL.
    # Methods in the module are called from only Sisimai::Message.
    module Yahoo
      # Imported from p5-Sisimail/lib/Sisimai/MSP/US/Yahoo.pm
      class << self
        require 'sisimai/msp'
        require 'sisimai/rfc5322'

        Re0 = {
          :subject => %r/\AFailure Notice\z/,
        }
        Re1 = {
          :begin   => %r/\ASorry, we were unable to deliver your message/,
          :rfc822  => %r/\A--- Below this line is a copy of the message[.]\z/,
          :endof   => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        Indicators = Sisimai::MSP.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'Yahoo! MAIL: https://www.yahoo.com'; end
        def smtpagent;   return 'US::Yahoo'; end

        # X-YMailISG: YtyUVyYWLDsbDh...
        # X-YMail-JAS: Pb65aU4VM1mei...
        # X-YMail-OSG: bTIbpDEVM1lHz...
        # X-Originating-IP: [192.0.2.9]
        def headerlist;  return ['X-YMailISG']; end
        def pattern;     return Re0; end

        # Parse bounce messages from Yahoo! MAIL
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
          return nil unless mhead['x-ymailisg']

          dscontents = []; dscontents << Sisimai::MSP.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          v = nil

          hasdivided.each do |e|
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
                previousfn = '';
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

              # Sorry, we were unable to deliver your message to the following address.
              #
              # <kijitora@example.org>:
              # Remote host said: 550 5.1.1 <kijitora@example.org>... User Unknown [RCPT_TO]
              v = dscontents[-1]

              if cv = e.match(/\A[<](.+[@].+)[>]:[ \t]*\z/)
                # <kijitora@example.org>:
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MSP.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              else
                if e =~ /\ARemote host said:/
                  # Remote host said: 550 5.1.1 <kijitora@example.org>... User Unknown [RCPT_TO]
                  v['diagnosis'] = e

                  if cv = e.match(/\[([A-Z]{4}).*\]\z/)
                    # Get SMTP command from the value of "Remote host said:"
                    v['command'] = cv[1]
                  end

                else
                  # <mailboxfull@example.jp>:
                  # Remote host said:
                  # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
                  # [RCPT_TO]
                  if v['diagnosis'] =~ /\ARemote host said:\z/
                    # Remote host said:
                    # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
                    if cv = e.match(/\[([A-Z]{4}).*\]\z/)
                      # [RCPT_TO]
                      v['command'] = cv[1]
                    else
                      # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
                      v['diagnosis'] = e
                    end
                  end

                end

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
              ['lhost', 'rhost'].each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = e['diagnosis'].gsub(/\\n/, ' ')
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            e['status']  = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['spec']  ||= 'SMTP'
            e['agent']   = Sisimai::MSP::US::Yahoo.smtpagent
          end

          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end
