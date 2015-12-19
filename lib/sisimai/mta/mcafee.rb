module Sisimai
  module MTA
    # Sisimai::MTA::McAfee parses a bounce email which created by McAfee Email
    # Appliance. Methods in the module are called from only Sisimai::Message.
    module McAfee
      # Imported from p5-Sisimail/lib/Sisimai/MTA/McAfee.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :'x-nai'   => %r/Modified by McAfee /,
          :'subject' => %r/\ADelivery Status\z/,
        }
        Re1 = {
          :begin   => %r/[-]+ The following addresses had delivery problems [-]+\z/,
          :error   => %r|\AContent-Type: [^ ]+/[^ ]+; name="deliveryproblems[.]txt"|,
          :rfc822  => %r|\AContent-Type: message/rfc822\z|,
          :endof   => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReFailure = {
          'userunknown' => %r{(?:
             User[ ][(].+[@].+[)][ ]unknown[.]
            |550[ ]Unknown[ ]user[ ][^ ]+[@][^ ]+
            )
          }x,
        }
        Indicators = Sisimai::MTA.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'McAfee Email Appliance'; end
        def smtpagent;   return 'McAfee'; end
        def headerlist;  return [ 'X-NAI-Header' ]; end
        def pattern;     return Re0; end

        # Parse bounce messages from McAfee Email Appliance
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
          return nil unless mhead['x-nai-header']
          return nil unless mhead['x-nai-header'] =~ Re0[:'x-nai']
          return nil unless mhead['subject']      =~ Re0[:'subject']

          require 'sisimai/address'
          dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          havepassed = [''];
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          diagnostic = ''     # (String) Alternative diagnostic message
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

              elsif e =~ /\A\s+/
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

              # Content-Type: text/plain; name="deliveryproblems.txt"
              #
              #    --- The following addresses had delivery problems ---
              #
              # <user@example.com>   (User unknown user@example.com)
              #
              # --------------Boundary-00=_00000000000000000000
              # Content-Type: message/delivery-status; name="deliverystatus.txt"
              #
              v = dscontents[-1]

              if cv = e.match(/\A[<]([^ ]+[@][^ ]+)[>]\s+[(](.+)[)]\z/)
                # <kijitora@example.co.jp>   (Unknown user kijitora@example.co.jp)
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                diagnostic = cv[2]
                recipients += 1

              elsif cv = e.match(/\A[Oo]riginal-[Rr]ecipient:[ ]*([^ ]+)\z/)
                # Original-Recipient: <kijitora@example.co.jp>
                v['alias'] = Sisimai::Address.s3s4(cv[1])

              elsif cv = e.match(/\A[Aa]ction:[ ]*(.+)\z/)
                # Action: failed
                v['action'] = cv[1].downcase

              elsif cv = e.match(/\A[Rr]emote-MTA:[ ]*(.+)\z/)
                # Remote-MTA: 192.0.2.192
                v['rhost'] = cv[1].downcase

              else
                if cv = e.match(/\A[Dd]iagnostic-[Cc]ode:[ ]*(.+?);[ ]*(.+)\z/)
                  # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                  v['spec'] = cv[1].upcase
                  v['diagnosis'] = cv[2]

                elsif p =~ /\A[Dd]iagnostic-[Cc]ode:[ ]*/ && cv = e.match(/\A\s+(.+)\z/)
                  # Continued line of the value of Diagnostic-Code header
                  v['diagnosis'] ||= ' '
                  v['diagnosis']  += ' ' + cv[1]
                  havepassed[-1] = 'Diagnostic-Code: ' + e
                end
              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            # Set default values if each value is empty.
            e['agent'] = Sisimai::MTA::McAfee.smtpagent

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              ['lhost', 'rhost'].each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'] || diagnostic)

            ReFailure.each_key do |r|
              # Verify each regular expression of session errors
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r
              break
            end

            e['status'] = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['spec']   = e['reason'] == 'mailererror' ? 'X-UNIX' : 'SMTP'
            e.each_key { |a| e[a] ||= '' }
          end

          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

