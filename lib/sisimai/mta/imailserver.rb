module Sisimai
  module MTA
    # Sisimai::MTA::IMailServer parses a bounce email which created by Ipswitch
    # IMail Server. Methods in the module are called from only Sisimai::Message.
    module IMailServer
      # Imported from p5-Sisimail/lib/Sisimai/MTA/IMailServer.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :'x-mailer' => %r/\A[<]SMTP32 v[\d.]+[>]\z/,
          :'subject'  => %r/\AUndeliverable Mail\z/,
        }
        Re1 = {
          :begin  => %r/\A\z/,    # Blank line
          :error  => %r/Body of message generated response:/,
          :rfc822 => %r/\AOriginal message follows[.]\z/,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReSMTP = {
          'conn' => %r{(?:
               SMTP[ ]connection[ ]failed,
              |Unexpected[ ]connection[ ]response[ ]from[ ]server:
              )
          },
          'ehlo' => %r|Unexpected response to EHLO/HELO:|,
          'mail' => %r|Server response to MAIL FROM:|,
          'rcpt' => %r|Additional RCPT TO generated following response:|,
          'data' => %r|DATA command generated response:|,
        }
        ReFailure = {
          'hostunknown' => %r{
              Unknown[ ]host
          },
          'userunknown' => %r{\A(?:
               Unknown[ ]user
              |Invalid[ ]final[ ]delivery[ ]userid    # Filtered ?
              )
          }x,
          'mailboxfull' => %r{
              \AUser[ ]mailbox[ ]exceeds[ ]allowed[ ]size
          }x,
          'securityerr' => %r{
              \ARequested[ ]action[ ]not[ ]taken:[ ]virus[ ]detected
          }x,
          'undefined' => %r{
              \Aundeliverable[ ]to[ ]
          }x,
          'expired' => %r{
              \ADelivery[ ]failed[ ]\d+[ ]attempts
          }x,
        }
        Indicators = Sisimai::MTA.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'IPSWITCH IMail Server'; end
        def smtpagent;   return 'IMailServer'; end
        def headerlist;  return ['X-Mailer']; end
        def pattern;     return Re0; end

        # Parse bounce messages from IMailServer
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

          match  = 0
          match += 1 if mhead['subject'] =~ Re0[:subject]
          match += 1 if mhead['x-mailer'] && mhead['x-mailer'] =~ Re0[:'x-mailer']
          return nil if match == 0

          dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
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
              break if readcursor & Indicators[:'message-rfc822'] > 0

              # Unknown user: kijitora@example.com
              #
              # Original message follows.
              v = dscontents[-1]

              if cv = e.match(/\A(.+)[ ](.+)[:][ \t]*([^ ]+[@][^ ]+)\z/)
                # Unknown user: kijitora@example.com
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['diagnosis'] = cv[1] + ' ' + cv[2]
                v['recipient'] = cv[3]
                recipients += 1

              elsif cv = e.match(/\Aundeliverable[ ]+to[ ]+(.+)\z/)
                # undeliverable to kijitora@example.com
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              else
                # Other error message text
                v['alterrors']  += ' ' + e if v['alterrors']
                if e =~ Re1[:error]
                  # Body of message generated response:
                  v['alterrors'] = e
                end
              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            # Set default values if each value is empty.
            e['agent'] = Sisimai::MTA::IMailServer.smtpagent

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              ['lhost', 'rhost'].each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end

            if e['alterrors'] && e['alterrors'].size > 0
              # Copy alternative error message
              if e['diagnosis']
                e['diagnosis'] = e['alterrors'] + ' ' + e['diagnosis']
              else
                e['diagnosis'] = e['alterrors']
              end
              e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
              e.delete('alterrors')
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            ReSMTP.each_key do |r|
              # Detect SMTP command from the message
              next unless e['diagnosis'] =~ ReSMTP[r]
              e['command'] = r.upcase
              break
            end

            ReFailure.each_key do |r|
              # Verify each regular expression of session errors
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r
              break
            end

            e['status'] = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['spec']   = e['reason'] == 'mailererror' ? 'X-UNIX' : 'SMTP'
            e['action'] = 'failed' if e['status'] =~ /\A[45]/
            e.each_key { |a| e[a] ||= '' }
          end

          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end
