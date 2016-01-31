module Sisimai
  module MTA
    # Sisimai::MTA::Domino parses a bounce email which created by IBM Domino Server.
    # Methods in the module are called from only Sisimai::Message.
    module Domino
      # Imported from p5-Sisimail/lib/Sisimai/MTA/Domino.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :subject => %r/\ADELIVERY FAILURE:/,
        }
        Re1 = {
          :begin   => %r/\AYour message/,
          :rfc822  => %r|\AContent-Type: message/delivery-status\z|,
          :endof   => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReFailure = {
          'userunknown' => %r{(?>
             not[ ]listed[ ]in[ ](?:
               Domino[ ]Directory
              |public[ ]Name[ ][&][ ]Address[ ]Book
              )
            |Domino[ ]ディレクトリには見つかりません
            )
          }x,
          'filtered' => %r{
              Cannot[ ]route[ ]mail[ ]to[ ]user
          }x,
          'systemerror' => %r{
              Several[ ]matches[ ]found[ ]in[ ]Domino[ ]Directory
          }x,
        }
        Indicators = Sisimai::MTA.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'IBM Domino Server'; end
        def smtpagent;   return 'Domino'; end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from IBM Domino Server
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
          return nil unless mhead['subject'] =~ Re0[:subject]

          dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          havepassed = [''];
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          subjecttxt = ''     # (String) The value of Subject:
          v = nil

          require 'sisimai/address'

          hasdivided.each do |e|
            # Save the current line for the next loop
            havepassed << e; p = havepassed[-2]
            next if e.empty?

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

              # Your message
              #
              #   Subject: Test Bounce
              #
              # was not delivered to:
              #
              #   kijitora@example.net
              #
              # because:
              #
              #   User some.name (kijitora@example.net) not listed in Domino Directory
              #
              v = dscontents[-1]

              if e =~ /\Awas not delivered to:\z/
                # was not delivered to:
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] ||= e
                recipients += 1

              elsif cv = e.match(/\A[ ][ ]([^ ]+[@][^ ]+)\z/)
                # Continued from the line "was not delivered to:"
                #   kijitora@example.net
                v['recipient'] = Sisimai::Address.s3s4(cv[1])

              elsif e =~ /\Abecause:\z/
                # because:
                v['diagnosis'] = e

              else

                if v['diagnosis'] && v['diagnosis'] == 'because:'
                  # Error message, continued from the line "because:"
                  v['diagnosis'] = e

                elsif cv = e.match(/\A[ ][ ]Subject: (.+)\z/)
                  #   Subject: Nyaa
                  subjecttxt = cv[1]
                end
              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            # Set default values if each value is empty.
            e['agent'] = Sisimai::MTA::Domino.smtpagent

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              ['lhost', 'rhost'].each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
            e['recipient'] = Sisimai::Address.s3s4(e['recipient'])

            ReFailure.each_key do |r|
              # Check each regular expression of Domino error messages
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r
              pseudostatus = Sisimai::SMTP::Status.code(r, false)
              e['status'] = pseudostatus if pseudostatus.size > 0
              break
            end

            e['spec'] = e['reason'] == 'mailererror' ? 'X-UNIX' : 'SMTP'
            e['action'] = 'failed' if e['status'] =~ /\A[45]/

            unless rfc822part =~ /\bSubject:/
              # Fallback: Add the value of Subject as a Subject header
              rfc822part += sprintf("Subject: %s\n", subjecttxt)
            end
            e.each_key { |a| e[a] ||= '' }
          end

          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

