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
          userunknown: %r{(?>
             not[ ]listed[ ]in[ ](?:
               Domino[ ]Directory
              |public[ ]Name[ ][&][ ]Address[ ]Book
              )
            |Domino[ ]ディレクトリには見つかりません
            )
          }x,
          filtered:    %r/Cannot[ ]route[ ]mail[ ]to[ ]user/x,
          systemerror: %r/Several[ ]matches[ ]found[ ]in[ ]Domino[ ]Directory/x,
        }
        Indicators = Sisimai::MTA.INDICATORS

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

          require 'sisimai/address'
          dscontents = [Sisimai::MTA.DELIVERYSTATUS]
          hasdivided = mbody.split("\n")
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          subjecttxt = ''     # (String) The value of Subject:
          v = nil

          hasdivided.each do |e|
            next if e.empty?

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
              %w|lhost rhost|.each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
            e['recipient'] = Sisimai::Address.s3s4(e['recipient'])

            ReFailure.each_key do |r|
              # Check each regular expression of Domino error messages
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r.to_s
              pseudostatus = Sisimai::SMTP::Status.code(r.to_s, false)
              e['status'] = pseudostatus if pseudostatus.size > 0
              break
            end

            e['spec'] = e['reason'] == 'mailererror' ? 'X-UNIX' : 'SMTP'
            e['action'] = 'failed' if e['status'] =~ /\A[45]/
            e.each_key { |a| e[a] ||= '' }
          end

          unless rfc822list.find { |a| a =~ /^Subject:/ }
            # Set the value of $subjecttxt as a Subject if there is no original
            # message in the bounce mail.
            rfc822list << sprintf('Subject: %s', subjecttxt)
          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

