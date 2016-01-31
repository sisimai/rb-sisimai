module Sisimai
  module MSP::US
    # Sisimai::MSP::US::Facebook parses a bounce email which created by Facebook.
    # Methods in the module are called from only Sisimai::Message.
    module Facebook
      # Imported from p5-Sisimail/lib/Sisimai/MSP/US/Facebook.pm
      class << self
        require 'sisimai/msp'
        require 'sisimai/rfc5322'

        Re0 = {
          :from    => %r/\AFacebook [<]mailer-daemon[@]mx[.]facebook[.]com[>]\z/,
          :subject => %r/\ASorry, your message could not be delivered\z/,
        }
        Re1 = {
          :begin   => %r/\AThis message was created automatically by Facebook[.]\z/,
          :rfc822  => %r/\AContent-Disposition: inline\z/,
          :endof   => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }

        # http://postmaster.facebook.com/response_codes
        # NOT TESTD EXCEPT RCP-P2
        ReFailure = {
          'userunknown' => [
            'RCP-P1',   # The attempted recipient address does not exist.
            'INT-P1',   # The attempted recipient address does not exist.
            'INT-P3',   # The attempted recpient group address does not exist.
            'INT-P4',   # The attempted recipient address does not exist.
          ],
          'filtered' => [
            'RCP-P2',   # The attempted recipient's preferences prevent messages from being delivered.
            'RCP-P3',   # The attempted recipient's privacy settings blocked the delivery.
          ],
          'mesgtoobig' => [
            'MSG-P1',   # The message exceeds Facebook's maximum allowed size.
            'INT-P2',   # The message exceeds Facebook's maximum allowed size.
          ],
          'contenterror' => [
            'MSG-P2',   # The message contains an attachment type that Facebook does not accept.
            'MSG-P3',   # The message contains multiple instances of a header field that can only be present once. Please see RFC 5322, section 3.6 for more information
            'POL-P6',   # The message contains a url that has been blocked by Facebook.
            'POL-P7',   # The message does not comply with Facebook's abuse policies and will not be accepted.
          ],
          'securityerror' => [
            'POL-P1',   # Your mail server's IP Address is listed on the Spamhaus PBL.
            'POL-P2',   # Facebook will no longer accept mail from your mail server's IP Address.
            'POL-P5',   # The message contains a virus.
            'POL-P7',   # The message does not comply with Facebook's Domain Authentication requirements.
          ],
          'notaccept' => [
            'POL-P3',   # Facebook is not accepting messages from your mail server. This will persist for 4 to 8 hours.
            'POL-P4',   # Facebook is not accepting messages from your mail server. This will persist for 24 to 48 hours.
            'POL-T1',   # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 1 to 2 hours.
            'POL-T2',   # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 4 to 8 hours.
            'POL-T3',   # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 24 to 48 hours.
          ],
          'rejected' => [
            'DNS-P1',   # Your SMTP MAIL FROM domain does not exist.
            'DNS-P2',   # Your SMTP MAIL FROM domain does not have an MX record.
            'DNS-T1',   # Your SMTP MAIL FROM domain exists but does not currently resolve.
            'DNS-P3',   # Your mail server does not have a reverse DNS record.
            'DNS-T2',   # You mail server's reverse DNS record does not currently resolve.
          ],
          'systemerror' => [
            'CON-T1',   # Facebook's mail server currently has too many connections open to allow another one.
          ],
          'undefined' => [
            'RCP-T1',   # The attempted recipient address is not currently available due to an internal system issue. This is a temporary condition.
            'MSG-T1',   # The number of recipients on the message exceeds Facebook's allowed maximum.
            'CON-T2',   # Your mail server currently has too many connections open to Facebook's mail servers.
            'CON-T3',   # Your mail server has opened too many new connections to Facebook's mail servers in a short period of time.
            'CON-T4',   # Your mail server has exceeded the maximum number of recipients for its current connection.
          ],
          'suspend' => [
            'RCP-T4',   # The attempted recipient address is currently deactivated. The user may or may not reactivate it.
          ],
        }
        Indicators = Sisimai::MSP.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'Facebook: https://www.facebook.com'; end
        def smtpagent;   return 'US::Facebook'; end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from Facebook
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
          return nil unless mhead['from']    =~ Re0[:from]
          return nil unless mhead['subject'] =~ Re0[:subject]

          dscontents = []; dscontents << Sisimai::MSP.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          havepassed = [''];
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          fbresponse = ''     # (String) Response code from Facebook
          connvalues = 0      # (Integer) Flag, 1 if all the value of $connheader have been set
          connheader = {
            'date'  => '',    # The value of Arrival-Date header
            'lhost' => '',    # The value of Reporting-MTA header
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

              if connvalues == connheader.keys.size
                # Reporting-MTA: dns; 10.138.205.200
                # Arrival-Date: Thu, 23 Jun 2011 02:29:43 -0700
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

                elsif cv = e.match(/\A[Xx]-[Aa]ctual-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*(.+)\z/)
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

                elsif cv = e.match(/\A[Rr]emote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Remote-MTA: DNS; mx.example.jp
                  v['rhost'] = cv[1].downcase

                elsif cv = e.match(/\A[Ll]ast-[Aa]ttempt-[Dd]ate:[ ]*(.+)\z/)
                  # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
                  v['date'] = cv[1]

                else
                  if cv = e.match(/\A[Dd]iagnostic-[Cc]ode:[ ]*(.+?);[ ]*(.+)\z/)
                    # Diagnostic-Code: smtp; 550 5.1.1 RCP-P2
                    #     http://postmaster.facebook.com/response_codes?ip=192.0.2.135#rcp Refused due to recipient preferences
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
                if cv = e.match(/\A[Rr]eporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Reporting-MTA: dns; mx.example.jp
                  next if connheader['lhost'].size > 0
                  connheader['lhost'] = cv[1].downcase
                  connvalues += 1

                elsif cv = e.match(/\A[Aa]rrival-[Dd]ate:[ ]*(.+)\z/)
                  # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                  next if connheader['date'].size > 0
                  connheader['date'] = cv[1]
                  connvalues += 1
                end

              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['lhost'] ||= connheader['lhost']

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              ['lhost', 'rhost'].each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            if cv = e['diagnosis'].match(/\b([A-Z]{3})[-]([A-Z])(\d)\b/)
              # Diagnostic-Code: smtp; 550 5.1.1 RCP-P2
              lhs = cv[1]
              rhs = cv[2]
              num = cv[3]

              fbresponse = sprintf("%s-%s%d", lhs, rhs, num)
              e['softbounce'] = rhs == 'P' ? 0 : 1
            end

            catch :SESSION do
              ReFailure.each_key do |r|
                # Verify each regular expression of session errors
                ReFailure[r].each do |rr|
                  # Check each regular expression
                  next unless fbresponse == rr
                  e['reason'] = r
                  throw :SESSION
                end
              end
            end

            unless e['reason']
              # http://postmaster.facebook.com/response_codes
              #   Facebook System Resource Issues
              #   These codes indicate a temporary issue internal to Facebook's
              #   system. Administrators observing these issues are not required to
              #   take any action to correct them.
              if fbresponse =~ /\AINT-T\d+\z/
                # * INT-Tx
                #
                # https://groups.google.com/forum/#!topic/cdmix/eXfi4ddgYLQ
                # This block has not been tested because we have no email sample
                # including "INT-T?" error code.
                e['reason'] = 'systemerror'
                e['softbounce'] = 1
              end
            end

            e['status'] = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['spec']   = e['reason'] == 'mailererror' ? 'X-UNIX' : 'SMTP'
            e['action'] = 'failed' if e['status'] =~ /\A[45]/
            e['agent']  = Sisimai::MSP::US::Facebook.smtpagent
          end

          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

