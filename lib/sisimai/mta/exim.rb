module Sisimai
  module MTA
    # Sisimai::MTA::Exim parses a bounce email which created by Exim. Methods in
    # the module are called from only Sisimai::Message.
    module Exim
      # Imported from p5-Sisimail/lib/Sisimai/MTA/Exim.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        ReE = {
          :from    => %r/[@].+[.]mail[.]ru[>]?/,
        }
        Re0 = {
          :from    => %r/\AMail Delivery System/,
          :subject => %r{(?:
             Mail[ ]delivery[ ]failed(:[ ]returning[ ]message[ ]to[ ]sender)?
            |Warning:[ ]message[ ].+[ ]delayed[ ]+
            |Delivery[ ]Status[ ]Notification
            |Mail[ ]failure
            |Message[ ]frozen
            |error[(]s[)][ ]in[ ]forwarding[ ]or[ ]filtering
            )
          }x,
          # :'message-id' => %r/\A[<]\w+[-]\w+[-]\w+[@].+\z/,
          # Message-Id: <E1P1YNN-0003AD-Ga@example.org>
        }

        # Error text regular expressions which defined in exim/src/deliver.c
        #
        # deliver.c:6292| fprintf(f,
        # deliver.c:6293|"This message was created automatically by mail delivery software.\n");
        # deliver.c:6294|        if (to_sender)
        # deliver.c:6295|          {
        # deliver.c:6296|          fprintf(f,
        # deliver.c:6297|"\nA message that you sent could not be delivered to one or more of its\n"
        # deliver.c:6298|"recipients. This is a permanent error. The following address(es) failed:\n");
        # deliver.c:6299|          }
        # deliver.c:6300|        else
        # deliver.c:6301|          {
        # deliver.c:6302|          fprintf(f,
        # deliver.c:6303|"\nA message sent by\n\n  <%s>\n\n"
        # deliver.c:6304|"could not be delivered to one or more of its recipients. The following\n"
        # deliver.c:6305|"address(es) failed:\n", sender_address);
        # deliver.c:6306|          }
        #
        # deliver.c:6423|          if (bounce_return_body) fprintf(f,
        # deliver.c:6424|"------ This is a copy of the message, including all the headers. ------\n");
        # deliver.c:6425|          else fprintf(f,
        # deliver.c:6426|"------ This is a copy of the message's headers. ------\n");
        Re1 = {
          :alias  => %r/\A([ ]+an[ ]undisclosed[ ]address)\z/,
          :frozen => %r/\AMessage .+ (?:has been frozen|was frozen on arrival)/,
          :rfc822 => %r{\A(?:
               [-]+[ ]This[ ]is[ ]a[ ]copy[ ]of[ ]the[ ]message.+headers[.][ ][-]+
              |Content-Type:[ ]*message/rfc822
              )\z
            }x,
          :begin  => %r{\A(?>
             This[ ]message[ ]was[ ]created[ ]automatically[ ]by[ ]mail[ ]delivery[ ]software[.]
            |A[ ]message[ ]that[ ]you[ ]sent[ ]was[ ]rejected[ ]by[ ]the[ ]local[ ]scanning[ ]code
            |Message[ ].+[ ](?:has[ ]been[ ]frozen|was[ ]frozen[ ]on[ ]arrival)
            |The[ ].+[ ]router[ ]encountered[ ]the[ ]following[ ]error[(]s[)]:
            )
           }x,
          :deliverystatus => %r|\AContent-type: message/delivery-status|,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }

        ReCommand = [
          # transports/smtp.c:564|  *message = US string_sprintf("SMTP error from remote mail server after %s%s: "
          # transports/smtp.c:837|  string_sprintf("SMTP error from remote mail server after RCPT TO:<%s>: "
          %r/SMTP error from remote (?:mail server|mailer) after ([A-Za-z]{4})/,
          %r/SMTP error from remote (?:mail server|mailer) after end of ([A-Za-z]{4})/,
          %r/LMTP error after ([A-Za-z]{4})/,
          %r/LMTP error after end of ([A-Za-z]{4})/,
        ]

        # find exim/ -type f -exec grep 'message = US' {} /dev/null \;
        ReFailure = {
          # route.c:1158|  DEBUG(D_uid) debug_printf("getpwnam() returned NULL (user not found)\n");
          userunknown: %r/user[ ]not[ ]found/x,
          # transports/smtp.c:3524|  addr->message = US"all host address lookups failed permanently";
          # routers/dnslookup.c:331|  addr->message = US"all relevant MX records point to non-existent hosts";
          # route.c:1826|  uschar *message = US"Unrouteable address";
          hostunknown: %r{(?>
             all[ ](?:
               host[ ]address[ ]lookups[ ]failed[ ]permanently
              |relevant[ ]MX[ ]records[ ]point[ ]to[ ]non[-]existent[ ]hosts
              )
            |Unrouteable[ ]address
            )
          }x,
          # transports/appendfile.c:2567|  addr->user_message = US"mailbox is full";
          # transports/appendfile.c:3049|  addr->message = string_sprintf("mailbox is full "
          # transports/appendfile.c:3050|  "(quota exceeded while writing to file %s)", filename);
          mailboxfull: %r/(?:mailbox[ ]is[ ]full:?|error:[ ]quota[ ]exceed)/x,
          # routers/dnslookup.c:328|  addr->message = US"an MX or SRV record indicated no SMTP service";
          # transports/smtp.c:3502|  addr->message = US"no host found for existing SMTP connection";
          notaccept: %r{(?:
             an[ ]MX[ ]or[ ]SRV[ ]record[ ]indicated[ ]no[ ]SMTP[ ]service
            |no[ ]host[ ]found[ ]for[ ]existing[ ]SMTP[ ]connection
            )
          }x,
          # deliver.c:5614|  addr->message = US"delivery to file forbidden";
          # deliver.c:5624|  addr->message = US"delivery to pipe forbidden";
          # transports/pipe.c:1156|  addr->user_message = US"local delivery failed";
          systemerror: %r{(?>
             delivery[ ]to[ ](?:file|pipe)[ ]forbidden
            |local[ ]delivery[ ]failed
            |LMTP[ ]error[ ]after[ ]
            )
          }x,
          # deliver.c:5425|  new->message = US"Too many \"Received\" headers - suspected mail loop";
          contenterror: %r/Too[ ]many[ ]["]Received["][ ]headers/x,
        }

        # retry.c:902|  addr->message = (addr->message == NULL)? US"retry timeout exceeded" :
        # deliver.c:7475|  "No action is required on your part. Delivery attempts will continue for\n"
        # smtp.c:3508|  US"retry time not reached for any host after a long failure period" :
        # smtp.c:3508|  US"all hosts have been failing for a long time and were last tried "
        #                 "after this message arrived";
        # deliver.c:7459|  print_address_error(addr, f, US"Delay reason: ");
        # deliver.c:7586|  "Message %s has been frozen%s.\nThe sender is <%s>.\n", message_id,
        # receive.c:4021|  moan_tell_someone(freeze_tell, NULL, US"Message frozen on arrival",
        # receive.c:4022|  "Message %s was frozen on arrival by %s.\nThe sender is <%s>.\n",
        ReDelayed = %r{(?:
           retry[ ]timeout[ ]exceeded
          |No[ ]action[ ]is[ ]required[ ]on[ ]your[ ]part
          |retry[ ]time[ ]not[ ]reached[ ]for[ ]any[ ]host[ ]after[ ]a[ ]long[ ]failure[ ]period
          |all[ ]hosts[ ]have[ ]been[ ]failing[ ]for[ ]a[ ]long[ ]time[ ]and[ ]were[ ]last[ ]tried
          |Delay[ ]reason:[ ]
          |Message[ ].+[ ](?:has[ ]been[ ]frozen|was[ ]frozen[ ]on[ ]arrival[ ]by[ ])
          )
        }x
        Indicators = Sisimai::MTA.INDICATORS

        def description; return 'Exim'; end
        def smtpagent;   return 'Exim'; end
        def headerlist;  return ['X-Failed-Recipients']; end
        def pattern;     return Re0; end

        # Parse bounce messages from Exim
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
          return nil if     mhead['from']    =~ ReE[:from]
          return nil unless mhead['from']    =~ Re0[:from]
          return nil unless mhead['subject'] =~ Re0[:subject]

          dscontents = [Sisimai::MTA.DELIVERYSTATUS]
          hasdivided = mbody.split("\n")
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          localhost0 = ''     # (String) Local MTA
          boundary00 = ''     # (String) Boundary string
          havepassed = {
            :deliverystatus => 0
          }
          v = nil

          if mhead['content-type']
            # Get the boundary string and set regular expression for matching with
            # the boundary string.
            require 'sisimai/mime'
            boundary00 = Sisimai::MIME.boundary(mhead['content-type']) || ''
          end

          hasdivided.each do |e|
            break if e =~ Re1[:endof]

            if readcursor == 0
              # Beginning of the bounce message or delivery status part
              if e =~ Re1[:begin]
                readcursor |= Indicators[:deliverystatus]
                next unless e =~ Re1[:frozen]
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
              #
              # A message that you sent could not be delivered to one or more of its
              # recipients. This is a permanent error. The following address(es) failed:
              #
              #  kijitora@example.jp
              #    SMTP error from remote mail server after RCPT TO:<kijitora@example.jp>:
              #    host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
              v = dscontents[-1]

              if cv = e.match(/\A[ ][ ]+([^ \t]+[@][^ \t]+[.][a-zA-Z]+)(:.+)?\z/) || e.match(Re1[:alias])
                #   kijitora@example.jp
                #   sabineko@example.jp: forced freeze
                #
                # deliver.c:4549|  printed = US"an undisclosed address";
                #   an undisclosed address
                #     (generated from kijitora@example.jp)
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              elsif cv = e.match(/\A[ ]+[(]generated[ ]from[ ](.+)[)]\z/) ||
                         e.match(/\A[ ]+generated[ ]by[ ]([^ \t]+[@][^ \t]+)/)
                #     (generated from kijitora@example.jp)
                #  pipe to |/bin/echo "Some pipe output"
                #    generated by userx@myhost.test.ex
                v['alias'] = cv[1]

              else
                next if e.empty?

                if e =~ Re1[:frozen]
                  # Message *** has been frozen by the system filter.
                  # Message *** was frozen on arrival by ACL.
                  v['alterrors'] ||= ''
                  v['alterrors']  += e + ' '

                else
                  if boundary00.size > 0
                    # --NNNNNNNNNN-eximdsn-MMMMMMMMMM
                    # Content-type: message/delivery-status
                    # ...
                    if cv = e.match(/\A[Rr]eporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                      # Reporting-MTA: dns; mx.example.jp
                      v['lhost'] = cv[1]

                    elsif cv = e.match(/\A[Aa]ction:[ ]*(.+)\z/)
                      # Action: failed
                      v['action'] = cv[1].downcase

                    elsif cv = e.match(/\A[Ss]tatus:[ ]*(\d[.]\d+[.]\d+)/)
                      # Status: 5.0.0
                      v['status'] = cv[1]

                    elsif cv = e.match(/\A[Dd]iagnostic-[Cc]ode:[ ]*(.+?);[ ]*(.+)\z/)
                      # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                      v['spec'] = cv[1].upcase
                      v['diagnosis'] = cv[2]

                    elsif cv = e.match(/\A[Ff]inal-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*(.+)\z/)
                      # Final-Recipient: rfc822;|/bin/echo "Some pipe output"
                      v['spec'] ||= cv[1] =~ /[@]/ ? 'SMTP' : 'X-UNIX'

                    else
                      # Error message ?
                      if havepassed[:deliverystatus] == 0
                        # Content-type: message/delivery-status
                        havepassed[:deliverystatus] = 1 if e =~ Re1[:deliverystatus]
                        v['alterrors'] ||= ''
                        v['alterrors']  += e + ' ' if e =~ /\A[ ]+/
                      end
                    end
                  else
                    if dscontents.size == recipients
                      # Error message
                      next unless e.size
                      v['diagnosis'] ||= ''
                      v['diagnosis']  += e + '  '

                    else
                      # Error message when email address above does not include '@'
                      # and domain part.
                      next unless e =~ /\A[ ]{4}/
                      v['alterrors'] ||= ''
                      v['alterrors']  += e + ' '
                    end
                  end
                end
              end
            end
          end

          if recipients > 0
            # Check "an undisclosed address", "unroutable address"
            dscontents.map do |q|
              # Replace the recipient address with the value of "alias"
              next unless q['alias']
              next unless q['alias'].size > 0
              if q['recipient'].empty? || q['recipient'] !~ /[@]/
                # The value of "recipient" is empty or does not include "@"
                q['recipient'] = q['alias']
              end
            end

          else
            # Fallback for getting recipient addresses
            if mhead['x-failed-recipients']
              # X-Failed-Recipients: kijitora@example.jp
              rcptinhead = mhead['x-failed-recipients'].split(',')
              rcptinhead.each { |a| a.lstrip!; a.rstrip!; }
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
          require 'sisimai/smtp/reply'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            # Set default values if each value is empty.
            e['agent']   = Sisimai::MTA::Exim.smtpagent
            e['lhost'] ||= localhost0

            unless e['diagnosis']
              # Empty Diagnostic-Code: or error message
              if boundary00.size > 0
                # --NNNNNNNNNN-eximdsn-MMMMMMMMMM
                # Content-type: message/delivery-status
                #
                # Reporting-MTA: dns; the.local.host.name
                #
                # Action: failed
                # Final-Recipient: rfc822;/a/b/c
                # Status: 5.0.0
                #
                # Action: failed
                # Final-Recipient: rfc822;|/p/q/r
                # Status: 5.0.0
                e['diagnosis'] = dscontents[0]['diagnosis'] || ''
                e['spec']    ||= dscontents[0]['spec']

                if dscontents[0]['alterrors'] && dscontents[0]['alterrors'].size > 0
                  # The value of "alterrors" is also copied
                  e['alterrors'] = dscontents[0]['alterrors']
                end
              end
            end

            if e['alterrors'] && e['alterrors'].size > 0
              # Copy alternative error message
              if e['diagnosis'].nil? || e['diagnosis'].empty?
                e['diagnosis'] ||= e['alterrors']
              end

              if e['diagnosis'] =~ /\A[-]+/ || e['diagnosis'] =~ /__\z/
                # Override the value of diagnostic code message
                e['diagnosis'] = e['alterrors'] if e['alterrors'].size > 0

              else
                # Check the both value and try to match
                if e['diagnosis'].size < e['alterrors'].size
                  # Check the value of alterrors
                  rxdiagnosis = %r/#{e['diagnosis']}/i
                  if e['alterrors'] =~ rxdiagnosis
                    # Override the value of diagnostic code message because
                    # the value of alterrors includes the value of diagnosis.
                    e['diagnosis'] = e['alterrors']
                  end
                end
              end
              e.delete('alterrors')
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''
            e['diagnosis'] = e['diagnosis'].sub(/\b__.+\z/, '')

            unless e['rhost']
              # Get the remote host name
              if cv = e['diagnosis'].match(/host[ \t]+([^ \t]+)[ \t]\[.+\]:[ \t]/)
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
                e['reason'] = 'onhold'

              else
                # Verify each regular expression of session errors
                ReFailure.each_key do |r|
                  # Check each regular expression
                  next unless e['diagnosis'] =~ ReFailure[r]
                  e['reason'] = r.to_s
                  break
                end

                unless e['reason']
                  # The reason "expired"
                  e['reason'] = 'expired' if e['diagnosis'] =~ ReDelayed
                end
              end
            end

            # Prefer the value of smtp reply code in Diagnostic-Code:
            # See eg/maildir-as-a-sample/new/exim-20.eml
            #   Action: failed
            #   Final-Recipient: rfc822;userx@test.ex
            #   Status: 5.0.0
            #   Remote-MTA: dns; 127.0.0.1
            #   Diagnostic-Code: smtp; 450 TEMPERROR: retry timeout exceeded
            # The value of "Status:" indicates permanent error but the value
            # of SMTP reply code in Diagnostic-Code: field is "TEMPERROR"!!!!
            sv = Sisimai::SMTP::Status.find(e['diagnosis'])
            rv = Sisimai::SMTP::Reply.find(e['diagnosis'])
            s1 = 0  # First character of Status as integer
            r1 = 0  # First character of SMTP reply code as integer

            # "Status:" field did not exist in the bounce message
            if sv.empty?
              # Check SMTP reply code
              if rv.size > 0
                # Generate pseudo DSN code from SMTP reply code
                r1 = rv[0, 1].to_i
                if r1 == 4
                  # Get the internal DSN(temporary error)
                  sv = Sisimai::SMTP::Status.code(e['reason'], true)

                elsif r1 == 5
                  # Get the internal DSN(permanent error)
                  sv = Sisimai::SMTP::Status.code(e['reason'], false)
                end
              end
            end

            s1  = sv[0, 1].to_i if sv.size > 0
            v1  = s1 + r1
            v1 += e['status'][0, 1].to_i if e['status']

            if v1 > 0
              # Status or SMTP reply code exists
              # Set pseudo DSN into the value of "status" accessor
              e['status'] = sv if r1 > 0
            else
              # Neither Status nor SMTP reply code exist
              if e['reason'] =~ /\A(?:expired|mailboxfull)/
                # Set pseudo DSN (temporary error)
                sv = Sisimai::SMTP::Status.code(e['reason'], true)

              else
                # Set pseudo DSN (permanent error)
                sv = Sisimai::SMTP::Status.code(e['reason'], false)
              end
            end
            e['status'] ||= sv
            e.each_key { |a| e[a] ||= '' }
          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

