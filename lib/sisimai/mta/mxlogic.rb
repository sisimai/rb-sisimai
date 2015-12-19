module Sisimai
  module MTA
    # Sisimai::MTA::MXLogic parses a bounce email which created by McAfee SaaS 
    # (formerly MX Logic). Methods in the module are called from only Sisimai::Message.
    module MXLogic
      # Imported from p5-Sisimail/lib/Sisimai/MTA/MXLogic.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        # Based on Sisimai::MTA::Exim
        Re0 = {
          :'from'      => %r/\AMail Delivery System/,
          :'subject'   => %r{(?:
               Mail[ ]delivery[ ]failed(:[ ]returning[ ]message[ ]to[ ]sender)?
              |Warning:[ ]message[ ].+[ ]delayed[ ]+
              |Delivery[ ]Status[ ]Notification
              )
          }x,
          :'message-id' => %r/\A[<]mxl[~][0-9a-f]+/,
        };
        Re1 = {
          :rfc822 => %r/\AIncluded is a copy of the message header:\z/,
          :begin  => %r/\AThis message was created automatically by mail delivery software[.]\z/,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReCommand = [
          %r/SMTP error from remote (?:mail server|mailer) after ([A-Za-z]{4})/,
          %r/SMTP error from remote (?:mail server|mailer) after end of ([A-Za-z]{4})/,
        ];

        ReFailure = {
          'userunknown' => %r{
              user[ ]not[ ]found
          }x,
          'hostunknown' => %r{(?>
               all[ ](?:
                   host[ ]address[ ]lookups[ ]failed[ ]permanently
                  |relevant[ ]MX[ ]records[ ]point[ ]to[ ]non[-]existent[ ]hosts
                  )
              |Unrouteable[ ]address
              )
          }x,
          'mailboxfull' => %r{(?:
               mailbox[ ]is[ ]full:?
              |error:[ ]quota[ ]exceed
              )
          }x,
          'notaccept' => %r{(?:
               an[ ]MX[ ]or[ ]SRV[ ]record[ ]indicated[ ]no[ ]SMTP[ ]service
              |no[ ]host[ ]found[ ]for[ ]existing[ ]SMTP[ ]connection
              )
          }x,
          'systemerror' => %r{(?>
               delivery[ ]to[ ](?:file|pipe)[ ]forbidden
              |local[ ]delivery[ ]failed
              |LMTP[ ]error[ ]after[ ]
              )
          }x,
          'contenterror' => %r{
              Too[ ]many[ ]["]Received["][ ]headers
          }x,
        }

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
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'McAfee SaaS'; end
        def smtpagent;   return 'MXLogic'; end
        # X-MX-Bounce: mta/src/queue/bounce
        # X-MXL-NoteHash: ffffffffffffffff-0000000000000000000000000000000000000000
        # X-MXL-Hash: 4c9d4d411993da17-bbd4212b6c887f6c23bab7db4bd87ef5edc00758
        def headerlist;  return ['X-MXL-NoteHash', 'X-MXL-Hash', 'X-MX-Bounce']; end
        def pattern;     return Re0; end

        # Parse bounce messages from MXLogic
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
          match += 1 if mhead['x-mx-bounce']
          match += 1 if mhead['x-mxl-hash']
          match += 1 if mhead['x-mxl-notehash']
          match += 1 if mhead['subject'] =~ Re0[:subject]
          match += 1 if mhead['from']    =~ Re0[:from]
          return nil if match == 0

          dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
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

              # This message was created automatically by mail delivery software.
              #
              # A message that you sent could not be delivered to one or more of its
              # recipients. This is a permanent error. The following address(es) failed:
              #
              #  kijitora@example.jp
              #    SMTP error from remote mail server after RCPT TO:<kijitora@example.jp>:
              #    host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
              v = dscontents[-1]

              if e =~ /\s*This is a permanent error[.]\s*/
                # deliver.c:6811|  "recipients. This is a permanent error. The following address(es) failed:\n");
                v['softbounce'] = 0

              elsif cv = e.match(/\A\s*[<]([^ ]+[@][^ ]+)[>]:(.+)\z/)
                # A message that you have sent could not be delivered to one or more
                # recipients.  This is a permanent error.  The following address failed:
                #
                #  <kijitora@example.co.jp>: 550 5.1.1 ...
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                v['diagnosis'] = cv[2]
                recipients += 1

              elsif dscontents.size == recipients
                # Error message
                next if e.empty?
                v['diagnosis'] ||= ''
                v['diagnosis']  += e + ' '
              end
            end
          end
          return nil if recipients == 0

          if mhead['received'].size > 0
            # Get the name of local MTA
            # Received: from marutamachi.example.org (c192128.example.net [192.0.2.128])
            if cv = mhead['received'][-1].match(/from\s([^ ]+) /)
              localhost0 = cv[1]
            end
          end

          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['agent'] = Sisimai::MTA::MXLogic.smtpagent
            e['lhost'] = localhost0

            e['diagnosis'] = e['diagnosis'].gsub(/[-]{2}.*\z/, '')
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            if !e['rhost']
              # Get the remote host name
              if cv = e['diagnosis'].match(/host\s+([^\s]+)\s\[.+\]:\s/)
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

            if !e['command']
              # Get the SMTP command name for the session
              ReCommand.each do |r|
                # Verify each regular expression of SMTP commands
                if cv = e['diagnosis'].match(r)
                  e['command'] = cv[1].upcase
                  break
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
                # Verify each regular expression of session errors
                ReFailure.each_key do |r|
                  # Check each regular expression
                  next unless e['diagnosis'] =~ ReFailure[r]
                  e['reason'] = r
                  break
                end

                unless e['reason']
                  # The reason "expired"
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

