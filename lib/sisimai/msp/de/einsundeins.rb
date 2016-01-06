module Sisimai
  module MSP::DE
    # Sisimai::MSP::DE::EinsUndEins parses a bounce email which created by 1&1.
    # Methods in the module are called from only Sisimai::Message.
    module EinsUndEins
      # Imported from p5-Sisimail/lib/Sisimai/MSP/DE/EinsUndEins.pm
      class << self
        require 'sisimai/msp'
        require 'sisimai/rfc5322'

        Re0 = {
          :from    => %r/\A["]Mail Delivery System["]/,
          :subject => %r/\AMail delivery failed: returning message to sender\z/,
        }
        Re1 = {
          :begin   => %r/\AThis message was created automatically by mail delivery software/,
          :error   => %r/\AFor the following reason:/,
          :rfc822  => %r/\A--- The header of the original message is following/,
          :endof   => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReFailure = {
          'mesgtoobig' => %r/Mail[ ]size[ ]limit[ ]exceeded/x,
        }
        Indicators = Sisimai::MSP.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return '1&1: http://www.1and1.de'; end
        def smtpagent;   return 'DE::EinsUndEins'; end
        # X-UI-Out-Filterresults: unknown:0;
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from 1&1
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

              # The following address failed:
              #
              # general@example.eu
              #
              # For the following reason:
              #
              # Mail size limit exceeded. For explanation visit
              # http://postmaster.1and1.com/en/error-messages?ip=%1s
              v = dscontents[-1]

              if cv = e.match(/\A([^ ]+[@][^ ]+)\z/)
                # general@example.eu
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MSP.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              elsif e =~ Re1[:error]
                # For the following reason:
                v['diagnosis'] = e

              else
                # Get error message
                if v['diagnosis']
                  # Append error message strings
                  v['diagnosis'] += ' ' + e
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
            e['diagnosis'] = e['diagnosis'].gsub(/\A#{Re1[:error]}/, '')
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            ReFailure.each_key do |r|
              # Verify each regular expression of session errors
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r
              break
            end

            e['status'] = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['spec']   = 'SMTP'
            e['agent']  = Sisimai::MSP::DE::EinsUndEins.smtpagent
          end

          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

