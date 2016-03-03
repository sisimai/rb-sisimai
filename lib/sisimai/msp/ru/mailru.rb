module Sisimai
  module MSP::RU
    # Sisimai::MSP::RU::MailRu parses a bounce email which created by @mail.ru.
    # Methods in the module are called from only Sisimai::Message.
    module MailRu
      # Imported from p5-Sisimail/lib/Sisimai/MSP/RU/MailRu.pm
      class << self
        require 'sisimai/msp'
        require 'sisimai/rfc5322'

        # Based on Sisimai::MTA::Exim
        Re0 = {
          # Message-Id: <E1P1YNN-0003AD-Ga@*.mail.ru>
          :'message-id' => %r/\A[<]\w+[-]\w+[-]\w+[@].*mail[.]ru[>]\z/,
          :'from'       => %r/[<]?mailer-daemon[@].*mail[.]ru[>]?/i,
          :'subject'    => %r{(?:
             Mail[ ]delivery[ ]failed(:[ ]returning[ ]message[ ]to[ ]sender)?
            |Warning:[ ]message[ ].+[ ]delayed[ ]+
            |Delivery[ ]Status[ ]Notification
            |Mail[ ]failure
            |Message[ ]frozen
            |error[(]s[)][ ]in[ ]forwarding[ ]or[ ]filtering
            )
          }x,
        }
        Re1 = {
          :rfc822 => %r/\A------ This is a copy of the message.+headers[.] ------\z/,
          :begin  => %r/\AThis message was created automatically by mail delivery software[.]/,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReCommand = [
          %r/SMTP error from remote (?:mail server|mailer) after ([A-Za-z]{4})/,
          %r/SMTP error from remote (?:mail server|mailer) after end of ([A-Za-z]{4})/,
        ]
        ReFailure = {
          expired: %r{(?:
               retry[ ]timeout[ ]exceeded
              |No[ ]action[ ]is[ ]required[ ]on[ ]your[ ]part
              )
          }x,
          userunknown: %r/user[ ]not[ ]found/x,
          hostunknown: %r{(?>
               all[ ](?:
                   host[ ]address[ ]lookups[ ]failed[ ]permanently
                  |relevant[ ]MX[ ]records[ ]point[ ]to[ ]non[-]existent[ ]hosts
                  )
              |Unrouteable[ ]address
              )
          }x,
          mailboxfull: %r/(?:mailbox[ ]is[ ]full:?|error:[ ]quota[ ]exceed)/x,
          notaccept: %r{(?:
               an[ ]MX[ ]or[ ]SRV[ ]record[ ]indicated[ ]no[ ]SMTP[ ]service
              |no[ ]host[ ]found[ ]for[ ]existing[ ]SMTP[ ]connection
              )
          }x,
          systemerror: %r{(?:
               delivery[ ]to[ ](?:file|pipe)[ ]forbidden
              |local[ ]delivery[ ]failed
              )
          }x,
          contenterror: %r/Too[ ]many[ ]["]Received["][ ]headers[ ]/x,
        }
        Indicators = Sisimai::MSP.INDICATORS

        def description; return '@mail.ru: https://mail.ru'; end
        def smtpagent;   return 'RU::MailRu'; end
        def headerlist;  return ['X-Failed-Recipients']; end
        def pattern;     return Re0; end

        # Parse bounce messages from @mail.ru
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
          return nil unless mhead['from']       =~ Re0[:from]
          return nil unless mhead['subject']    =~ Re0[:subject]
          return nil unless mhead['message-id'] =~ Re0[:'message-id']

          dscontents = []; dscontents << Sisimai::MSP.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          localhost0 = ''     # (String) Local MTA
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

              # Это письмо создано автоматически
              # сервером Mail.Ru, # отвечать на него не
              # нужно.
              #
              # К сожалению, Ваше письмо не может
              # быть# доставлено одному или нескольким
              # получателям:
              #
              # **********************
              #
              # This message was created automatically by mail delivery software.
              #
              # A message that you sent could not be delivered to one or more of its
              # recipients. This is a permanent error. The following address(es) failed:
              #
              #  kijitora@example.jp
              #    SMTP error from remote mail server after RCPT TO:<kijitora@example.jp>:
              #    host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
              v = dscontents[-1]

              if e =~ /[ \t]*This is a permanent error[.][ \t]*/
                # recipients. This is a permanent error. The following address(es) failed:
                v['softbounce'] = 0

              elsif cv = e.match(/\A[ \t]+([^ \t]+[@][^ \t]+[.][a-zA-Z]+)\z/)
                #   kijitora@example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MSP.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              elsif dscontents.size == recipients
                # Error message
                next if e.empty?
                v['diagnosis'] ||= ''
                v['diagnosis']  += e + ' '

              else
                # Error message when email address above does not include '@'
                # and domain part.
                next unless e =~ /\A[ \t]{4}/
                v['alterrors'] ||= ''
                v['alterrors']  += e + ' '
              end
            end
          end

          if recipients == 0
            # Fallback for getting recipient addresses
            if mhead['x-failed-recipients']
              # X-Failed-Recipients: kijitora@example.jp
              rcptinhead = mhead['x-failed-recipients'].split(',')
              rcptinhead.each { |a| a.delete(' ') }
              recipients = rcptinhead.size

              rcptinhead.each do |e|
                # Insert each recipient address into @$dscontents
                dscontents[-1]['recipient'] = e
                next if dscontents.size == recipients
                dscontents << Sisimai::MTA.DELIVERYSTATUS
              end
            end
          end
          return nil if recipients == 0

          if mhead['received'].size > 0
            # Get the name of local MTA
            # Received: from marutamachi.example.org (c192128.example.net [192.0.2.128])
            if cv = mhead['received'][-1].match(/from[ \t]([^ ]+)/)
              localhost0 = cv[1]
            end
          end
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            # Set default values if each value is empty.
            e['lhost'] ||= localhost0

            if e['alterrors'] && e['alterrors'].size > 0
              # Copy alternative error message
              e['diagnosis'] ||= e['alterrors']
              if e['diagnosis'] =~ /\A[-]+/ || e['diagnosis'] =~ /__\z/
                # Override the value of diagnostic code message
                e['diagnosis'] = e['alterrors'] if e['alterrors'].size > 0
              end
              e.delete('alterrors')
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''
            e['diagnosis'] = e['diagnosis'].sub(/\b__.+\z/, '')

            unless e['rhost']
              # Get the remote host name
              if cv = e['diagnosis'].match(/host[ ]+([^ \t]+)[ ]\[.+\]:[ ]/)
                # host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
                e['rhost'] = cv[1]
              end

              unless e['rhost']
                if mhead['received'].size > 0
                  # Get localhost and remote host name from Received header.
                  e['rhost'] = Sisimai::RFC5322.received(mhead['received'][-1]).pop
                end
              end
            end

            unless e['command']
              # Get the SMTP command name for the session
              ReCommand.each do |r|
                # Verify each regular expression of SMTP commands
                if cv = e['diagnosis'].match(r)
                  e['command'] = cv[1].upcase
                  break
                end
              end

              # Detect the reason of bounce
              if e['command'] =~ /\A(?:HELO|EHLO)\z/
                # HELO | Connected to 192.0.2.135 but my name was rejected.
                e['reason'] = 'blocked'

              elsif e['command'] == 'MAIL'
                # MAIL | Connected to 192.0.2.135 but sender was rejected.
                e['reason'] = 'rejected'

              else
                # Verify each regular expression of session errors
                ReFailure.each_key do |r|
                  # Check each regular expression
                  next unless e['diagnosis'] =~ ReFailure[r]
                  e['reason'] = r.to_s
                  break
                end
              end
            end

            e['status']    = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['spec']      = e['reason'] == 'mailererror' ? 'X-UNIX' : 'SMTP'
            e['action']    = 'failed' if e['status'] =~ /\A[45]/
            e['command'] ||= ''
            e['agent']     = Sisimai::MSP::RU::MailRu.smtpagent
          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

