module Sisimai
  module MTA
    # Sisimai::MTA::Qmail parses a bounce email which created by qmail. Methods
    # in the module are called from only Sisimai::Message.
    module Qmail
      # Imported from p5-Sisimail/lib/Sisimai/MTA/qmail.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :subject  => %r/\Afailure notice/i,
          :received => %r/\A[(]qmail[ ]+\d+[ ]+invoked[ ]+(?:for[ ]+bounce|from[ ]+network)[)]/,
        }
        #  qmail-remote.c:248|    if (code >= 500) {
        #  qmail-remote.c:249|      out("h"); outhost(); out(" does not like recipient.\n");
        #  qmail-remote.c:265|  if (code >= 500) quit("D"," failed on DATA command");
        #  qmail-remote.c:271|  if (code >= 500) quit("D"," failed after I sent the message");
        #
        # Characters: K,Z,D in qmail-qmqpc.c, qmail-send.c, qmail-rspawn.c
        #  K = success, Z = temporary error, D = permanent error
        Re1 = {
          :begin  => %r/\AHi[.] This is the qmail/,
          :rfc822 => %r/\A--- Below this line is a copy of the message[.]\z/,
          :error  => %r/\ARemote host said:/,
          :sorry  => %r/\A[Ss]orry[,.][ ]/,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReSMTP = {
          # Error text regular expressions which defined in qmail-remote.c
          # qmail-remote.c:225|  if (smtpcode() != 220) quit("ZConnected to "," but greeting failed");
          'conn' => %r/(?:Error:)?Connected[ ]to[ ].+[ ]but[ ]greeting[ ]failed[.]/x,
          # qmail-remote.c:231|  if (smtpcode() != 250) quit("ZConnected to "," but my name was rejected");
          'ehlo' => %r/(?:Error:)?Connected[ ]to[ ].+[ ]but[ ]my[ ]name[ ]was[ ]rejected[.]/x,
          # qmail-remote.c:238|  if (code >= 500) quit("DConnected to "," but sender was rejected");
          # reason = rejected
          'mail' => %r/(?:Error:)?Connected[ ]to[ ].+[ ]but[ ]sender[ ]was[ ]rejected[.]/x,
          # qmail-remote.c:249|  out("h"); outhost(); out(" does not like recipient.\n");
          # qmail-remote.c:253|  out("s"); outhost(); out(" does not like recipient.\n");
          # reason = userunknown
          'rcpt' => %r/(?:Error:)?.+[ ]does[ ]not[ ]like[ ]recipient[.]/x,
          # qmail-remote.c:265|  if (code >= 500) quit("D"," failed on DATA command");
          # qmail-remote.c:266|  if (code >= 400) quit("Z"," failed on DATA command");
          # qmail-remote.c:271|  if (code >= 500) quit("D"," failed after I sent the message");
          # qmail-remote.c:272|  if (code >= 400) quit("Z"," failed after I sent the message");
          'data' => %r{(?:
             (?:Error:)?.+[ ]failed[ ]on[ ]DATA[ ]command[.]
            |(?:Error:)?.+[ ]failed[ ]after[ ]I[ ]sent[ ]the[ ]message[.]
            )
          }x,
        }
        # qmail-remote.c:261|  if (!flagbother) quit("DGiving up on ","");
        ReHost = %r{(?:
           Giving[ ]up[ ]on[ ](.+[0-9a-zA-Z])[.]?\z
          |Connected[ ]to[ ]([-0-9a-zA-Z.]+[0-9a-zA-Z])[ ]
          |remote[ ]host[ ]([-0-9a-zA-Z.]+[0-9a-zA-Z])[ ]said:
          )
        }x
        ReLDAP = {
          # qmail-ldap-1.03-20040101.patch:19817 - 19866
          'suspend'     => %r/Mailaddress is administrative?le?y disabled/,            # 5.2.1
          'userunknown' => %r/[Ss]orry, no mailbox here by that name/,                 # 5.1.1
          'exceedlimit' => %r/The message exeeded the maximum size the user accepts/,  # 5.2.3
          'systemerror' => %r{(?>
             Automatic[ ]homedir[ ]creator[ ]crashed                    # 4.3.0
            |Illegal[ ]value[ ]in[ ]LDAP[ ]attribute                    # 5.3.5
            |LDAP[ ]attribute[ ]is[ ]not[ ]given[ ]but[ ]mandatory      # 5.3.5
            |Timeout[ ]while[ ]performing[ ]search[ ]on[ ]LDAP[ ]server # 4.4.3
            |Too[ ]many[ ]results[ ]returned[ ]but[ ]needs[ ]to[ ]be[ ]unique # 5.3.5
            |Permanent[ ]error[ ]while[ ]executing[ ]qmail[-]forward    # 5.4.4
            |Temporary[ ](?:
               error[ ](?:
                 in[ ]automatic[ ]homedir[ ]creation            # 4.3.0 or 5.3.0
                |while[ ]executing[ ]qmail[-]forward            # 4.4.4
                )
              |failure[ ]in[ ]LDAP[ ]lookup                       # 4.4.3
              )
            |Unable[ ]to[ ](?:
               contact[ ]LDAP[ ]server                            # 4.4.3
              |login[ ]into[ ]LDAP[ ]server,[ ]bad[ ]credentials  # 4.4.3
              )
            )
          }x,
        }
        # userunknown + expired
        ReOnHold  = %r/\A[^ ]+ does not like recipient[.][ ]+.+this message has been in the queue too long[.]\z/
        # qmail-remote-fallback.patch
        ReCommand = %r/Sorry,[ ]no[ ]SMTP[ ]connection[ ]got[ ]far[ ]enough;[ ]most[ ]progress[ ]was[ ]([A-Z]{4})[ ]/x
        ReFailure = {
          # qmail-local.c:589|  strerr_die1x(100,"Sorry, no mailbox here by that name. (#5.1.1)");
          # qmail-remote.c:253|  out("s"); outhost(); out(" does not like recipient.\n");
          'userunknown' => %r{(?:
             no[ ]mailbox[ ]here[ ]by[ ]that[ ]name
            |[ ]does[ ]not[ ]like[ ]recipient[.]
            )
          }x,
          # error_str.c:192|  X(EDQUOT,"disk quota exceeded")
          'mailboxfull' => %r/disk[ ]quota[ ]exceeded/x,
          # qmail-qmtpd.c:233| ... result = "Dsorry, that message size exceeds my databytes limit (#5.3.4)";
          # qmail-smtpd.c:391| ... out("552 sorry, that message size exceeds my databytes limit (#5.3.4)\r\n"); return;
          'mesgtoobig' => %r/Message[ ]size[ ]exceeds[ ]fixed[ ]maximum[ ]message[ ]size:/x,
          # qmail-remote.c:68|  Sorry, I couldn't find any host by that name. (#4.1.2)\n"); zerodie();
          # qmail-remote.c:78|  Sorry, I couldn't find any host named ");
          'hostunknown' => %r/\ASorry[,][ ]I[ ]couldn[']t[ ]find[ ]any[ ]host[ ]/x,
          'systemerror' => %r{(?>
             bad[ ]interpreter:[ ]No[ ]such[ ]file[ ]or[ ]directory
            |system[ ]error
            |Unable[ ]to\b
            )
          }x,
          'networkerror' => %r{Sorry(?:
             [,][ ]I[ ]wasn[']t[ ]able[ ]to[ ]establish[ ]an[ ]SMTP[ ]connection
            |[,][ ]I[ ]couldn[']t[ ]find[ ]a[ ]mail[ ]exchanger[ ]or[ ]IP[ ]address
            |[.][ ]Although[ ]I[']m[ ]listed[ ]as[ ]a[ ]best[-]preference[ ]MX[ ]
                or[ ]A[ ]for[ ]that[ ]host
            )
          }x,
          'systemfull' => %r/Requested action not taken: mailbox unavailable [(]not enough free space[)]/,
        }
        # qmail-send.c:922| ... (&dline[c],"I'm not going to try again; this message has been in the queue too long.\n")) nomem();
        ReDelayed  = %r/this[ ]message[ ]has[ ]been[ ]in[ ]the[ ]queue[ ]too[ ]long[.]\z/x

        Indicators = Sisimai::MTA.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'qmail'; end
        def smtpagent;   return 'qmail'; end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from qmail
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

          # Pre process email headers and the body part of the message which generated
          # by qmail, see http://cr.yp.to/qmail.html
          #   e.g.) Received: (qmail 12345 invoked for bounce); 29 Apr 2009 12:34:56 -0000
          #         Subject: failure notice
          match  = 0
          match += 1 if mhead['subject'] =~ Re0[:subject]
          match += 1 if mhead['received'].find { |a| a =~ Re0[:received] }
          return nil if match == 0

          dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          havepassed = [''];
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
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

              # <kijitora@example.jp>:
              # 192.0.2.153 does not like recipient.
              # Remote host said: 550 5.1.1 <kijitora@example.jp>... User Unknown
              # Giving up on 192.0.2.153.
              v = dscontents[-1]

              if cv = e.match(/\A(?:To[ ]*:)?[<](.+[@].+)[>]:[ \t]*\z/)
                # <kijitora@example.jp>:
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              elsif dscontents.size == recipients
                # Append error message
                next if e.empty?
                v['diagnosis'] ||= ''
                v['diagnosis']  += e + ' '
                v['alterrors']   = e if e =~ Re1[:error]

                next if v['rhost']
                if cv = e.match(ReHost)
                  v['rhost'] = cv[1]
                end
              end
            end
          end
          return nil if recipients == 0

          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            # Set default values if each value is empty.
            e['agent'] = Sisimai::MTA::Qmail.smtpagent

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              ['lhost', 'rhost'].each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''

            unless e['command']
              # Get the SMTP command name for the session
              ReSMTP.each_key do |r|
                # Verify each regular expression of SMTP commands
                next unless e['diagnosis'] =~ ReSMTP[r]
                e['command'] = r.upcase
                break
              end

              unless e['command']
                # Verify each regular expression of patches
                if cv = e['diagnosis'].match(ReCommand)
                  e['command'] = cv[1].upcase
                end
                e['command'] ||= ''
              end
            end

            # Detect the reason of bounce
            if e['command'] == 'MAIL'
              # MAIL | Connected to 192.0.2.135 but sender was rejected.
              e['reason'] = 'rejected'

            elsif e['command'] =~ /\A(?:HELO|EHLO)\z/
              # HELO | Connected to 192.0.2.135 but my name was rejected.
              e['reason'] = 'blocked'

            else
              # Try to match with each error message in the table
              if e['diagnosis'] =~ ReOnHold
                # To decide the reason require pattern match with
                # Sisimai::Reason::* modules
                e['reason'] = 'onhold'

              else
                ReFailure.each_key do |r|
                  # Verify each regular expression of session errors
                  if e['alterrors']
                    # Check the value of "alterrors"
                    next unless e['alterrors'] =~ ReFailure[r]
                    e['reason'] = r
                  end
                  break if e['reason']

                  next unless e['diagnosis'] =~ ReFailure[r]
                  e['reason'] = r
                  break
                end

                unless e['reason']
                  ReLDAP.each_key do |r|
                    # Verify each regular expression of LDAP errors
                    next unless e['diagnosis'] =~ ReLDAP[r]
                    e['reason'] = r
                    break
                  end
                end

                unless e['reason']
                  e['reason'] = 'expired' if e['diagnosis'] =~ ReDelayed
                end
              end
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

