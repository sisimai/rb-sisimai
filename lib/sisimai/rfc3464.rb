module Sisimai
  # Sisimai::RFC3464 - bounce mail parser class for Fallback.
  module RFC3464
    # Imported from p5-Sisimail/lib/Sisimai/RFC3464.pm
    class << self
      require 'sisimai/bite/email'

      # http://tools.ietf.org/html/rfc3464
      Re0 = {
        :'from'        => %r/\b(?:postmaster|mailer-daemon|root)[@]/i,
        :'return-path' => %r/(?:[<][>]|mailer-daemon)/i,
        :'subject'     => %r{(?>
           delivery[ ](?:failed|failure|report)
          |failure[ ]notice
          |mail[ ](?:delivery|error)
          |non[-]delivery
          |returned[ ]mail
          |undeliverable[ ]mail
          |Warning:[ ]
          )
        }xi,
      }.freeze
      Re1 = {
        :begin   => %r{\A(?>
           Content-Type:[ ]*(?:
             message/delivery-status
            |message/disposition-notification
            |text/plain;[ ]charset=
            )
          |The[ ]original[ ]message[ ]was[ ]received[ ]at[ ]
          |This[ ]report[ ]relates[ ]to[ ]your[ ]message
          |Your[ ]message[ ]was[ ]not[ ]delivered[ ]to[ ]the[ ]following[ ]recipients
          )
        }xi,
        :endof   => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        :rfc822  => %r{\A(?>
           Content-Type:[ ]*(?:message/rfc822|text/rfc822-headers)
          |Return-Path:[ ]*[<].+[>]\z
          )\z
        }xi,
        :error   => %r/\A(?:[45]\d\d[ \t]+|[<][^@]+[@][^@]+[>]:?[ \t]+)/i,
        :command => %r/[ ](RCPT|MAIL|DATA)[ ]+command\b/,
      }.freeze
      Indicators = Sisimai::Bite::Email.INDICATORS

      def description; 'Fallback Module for MTAs'; end
      def smtpagent;   'RFC3464'; end
      def headerlist;  return []; end

      # Detect an error for RFC3464
      # @param         [Hash] mhead       Message headers of a bounce email
      # @options mhead [String] from      From header
      # @options mhead [String] date      Date header
      # @options mhead [String] subject   Subject header
      # @options mhead [Array]  received  Received headers
      # @options mhead [String] others    Other required headers
      # @param         [String] mbody     Message body of a bounce email
      # @return        [Hash, Nil]        Bounce data list and message/rfc822 part
      #                                   or nil if it failed to parse or the
      def scan(mhead, mbody)
        return nil unless mhead
        return nil unless mbody
        return nil if mhead.keys.size.zero?
        return nil if mbody.empty?

        require 'sisimai/mda'
        require 'sisimai/address'

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.scrub('?').split("\n")
        havepassed = ['']
        scannedset = Sisimai::MDA.scan(mhead, mbody)
        rfc822list = []   # (Array) Each line in message/rfc822 part string
        blanklines = 0    # (Integer) The number of blank lines
        readcursor = 0    # (Integer) Points the current cursor position
        recipients = 0    # (Integer) The number of 'Final-Recipient' header
        connheader = {
          'date'  => nil, # The value of Arrival-Date header
          'rhost' => nil, # The value of Reporting-MTA header
          'lhost' => nil, # The value of Received-From-MTA header
        }
        v = nil

        hasdivided.each do |e|
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor.zero?
            # Beginning of the bounce message or delivery status part
            if e =~ Re1[:begin]
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']).zero?
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
            next unless readcursor & Indicators[:deliverystatus] > 0
            next unless e.size > 0

            v = dscontents[-1]
            if cv = e.match(/\A(?:[Ff]inal|[Oo]riginal)-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/) ||
                    e.match(/\A(?:[Ff]inal|[Oo]riginal)-[Rr]ecipient:[ ]*([^ ]+)\z/)
              # 2.3.2 Final-Recipient field
              #   The Final-Recipient field indicates the recipient for which this set
              #   of per-recipient fields applies.  This field MUST be present in each
              #   set of per-recipient data.
              #   The syntax of the field is as follows:
              #
              #       final-recipient-field =
              #           "Final-Recipient" ":" address-type ";" generic-address
              #
              # 2.3.1 Original-Recipient field
              #   The Original-Recipient field indicates the original recipient address
              #   as specified by the sender of the message for which the DSN is being
              #   issued.
              #
              #       original-recipient-field =
              #           "Original-Recipient" ":" address-type ";" generic-address
              #
              #       generic-address = *text
              x = v['recipienet'] || ''
              y = Sisimai::Address.s3s4(cv[1])

              if x.size > 0 && x != y
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = y
              recipients += 1

            elsif cv = e.match(/\A[Xx]-[Aa]ctual-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
              # X-Actual-Recipient:
              if cv[1] =~ /[ \t]+/
                # X-Actual-Recipient: RFC822; |IFS=' ' && exec procmail -f- || exit 75 ...

              else
                # X-Actual-Recipient: rfc822; kijitora@neko.example.jp
                v['alias'] = cv[1]
              end

            elsif cv = e.match(/\A[Aa]ction:[ ]*(.+)\z/)
              # 2.3.3 Action field
              #   The Action field indicates the action performed by the Reporting-MTA
              #   as a result of its attempt to deliver the message to this recipient
              #   address.  This field MUST be present for each recipient named in the
              #   DSN.
              #   The syntax for the action-field is:
              #
              #       action-field = "Action" ":" action-value
              #       action-value =
              #           "failed" / "delayed" / "delivered" / "relayed" / "expanded"
              #
              #   The action-value may be spelled in any combination of upper and lower
              #   case characters.
              v['action'] = cv[1].downcase

              if cv = v['action'].match(/\A([^ ]+)[ ]/)
                # failed (bad destination mailbox address)
                v['action'] = cv[1]
              end

            elsif cv = e.match(/\A[Ss]tatus:[ ]*(\d[.]\d+[.]\d+)/)
              # 2.3.4 Status field
              #   The per-recipient Status field contains a transport-independent
              #   status code that indicates the delivery status of the message to that
              #   recipient.  This field MUST be present for each delivery attempt
              #   which is described by a DSN.
              #
              #   The syntax of the status field is:
              #
              #       status-field = "Status" ":" status-code
              #       status-code = DIGIT "." 1*3DIGIT "." 1*3DIGIT
              v['status'] = cv[1]

            elsif cv = e.match(/\A[Ss]tatus:[ ]*(\d+[ ]+.+)\z/)
              # Status: 553 Exceeded maximum inbound message size
              v['alterrors'] = cv[1]

            elsif cv = e.match(/\A[Rr]emote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
              # 2.3.5 Remote-MTA field
              #   The value associated with the Remote-MTA DSN field is a printable
              #   ASCII representation of the name of the "remote" MTA that reported
              #   delivery status to the "reporting" MTA.
              #
              #       remote-mta-field = "Remote-MTA" ":" mta-name-type ";" mta-name
              #
              #   NOTE: The Remote-MTA field preserves the "while talking to"
              #   information that was provided in some pre-existing nondelivery
              #   reports.
              #
              #   This field is optional.  It MUST NOT be included if no remote MTA was
              #   involved in the attempted delivery of the message to that recipient.
              v['rhost'] = cv[1].downcase

            elsif cv = e.match(/\A[Ll]ast-[Aa]ttempt-[Dd]ate:[ ]*(.+)\z/)
              # 2.3.7 Last-Attempt-Date field
              #   The Last-Attempt-Date field gives the date and time of the last
              #   attempt to relay, gateway, or deliver the message (whether successful
              #   or unsuccessful) by the Reporting MTA.  This is not necessarily the
              #   same as the value of the Date field from the header of the message
              #   used to transmit this delivery status notification: In cases where
              #   the DSN was generated by a gateway, the Date field in the message
              #   header contains the time the DSN was sent by the gateway and the DSN
              #   Last-Attempt-Date field contains the time the last delivery attempt
              #   occurred.
              #
              #       last-attempt-date-field = "Last-Attempt-Date" ":" date-time
              v['date'] = cv[1]

            else
              if cv = e.match(/\A[Dd]iagnostic-[Cc]ode:[ ]*(.+?);[ ]*(.+)\z/)
                # 2.3.6 Diagnostic-Code field
                #   For a "failed" or "delayed" recipient, the Diagnostic-Code DSN field
                #   contains the actual diagnostic code issued by the mail transport.
                #   Since such codes vary from one mail transport to another, the
                #   diagnostic-type sub-field is needed to specify which type of
                #   diagnostic code is represented.
                #
                #       diagnostic-code-field =
                #           "Diagnostic-Code" ":" diagnostic-type ";" *text
                v['spec'] = cv[1].upcase
                v['diagnosis'] = cv[2]

              elsif cv = e.match(/\A[Dd]iagnostic-[Cc]ode:[ ]*(.+)\z/)
                # No value of "diagnostic-type"
                # Diagnostic-Code: 554 ...
                v['diagnosis'] = cv[1]

              elsif p =~ /\A[Dd]iagnostic-[Cc]ode:[ ]*/ && cv = e.match(/\A[ \t]+(.+)\z/)
                # Continued line of the value of Diagnostic-Code header
                v['diagnosis'] << ' ' << cv[1]
                e = 'Diagnostic-Code: ' << e

              else
                if cv = e.match(/\A[Rr]eporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # 2.2.2 The Reporting-MTA DSN field
                  #
                  #       reporting-mta-field =
                  #           "Reporting-MTA" ":" mta-name-type ";" mta-name
                  #       mta-name = *text
                  #
                  #   The Reporting-MTA field is defined as follows:
                  #
                  #   A DSN describes the results of attempts to deliver, relay, or gateway
                  #   a message to one or more recipients.  In all cases, the Reporting-MTA
                  #   is the MTA that attempted to perform the delivery, relay, or gateway
                  #   operation described in the DSN.  This field is required.
                  connheader['rhost'] ||= cv[1].downcase

                elsif cv = e.match(/\A[Rr]eceived-[Ff]rom-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # 2.2.4 The Received-From-MTA DSN field
                  #   The optional Received-From-MTA field indicates the name of the MTA
                  #   from which the message was received.
                  #
                  #       received-from-mta-field =
                  #           "Received-From-MTA" ":" mta-name-type ";" mta-name
                  #
                  #   If the message was received from an Internet host via SMTP, the
                  #   contents of the mta-name sub-field SHOULD be the Internet domain name
                  #   supplied in the HELO or EHLO command, and the network address used by
                  #   the SMTP client SHOULD be included as a comment enclosed in
                  #   parentheses.  (In this case, the MTA-name-type will be "dns".)
                  connheader['lhost'] = cv[1].downcase

                elsif cv = e.match(/\A[Aa]rrival-[Dd]ate:[ ]*(.+)\z/)
                  # 2.2.5 The Arrival-Date DSN field
                  #   The optional Arrival-Date field indicates the date and time at which
                  #   the message arrived at the Reporting MTA.  If the Last-Attempt-Date
                  #   field is also provided in a per-recipient field, this can be used to
                  #   determine the interval between when the message arrived at the
                  #   Reporting MTA and when the report was issued for that recipient.
                  #
                  #       arrival-date-field = "Arrival-Date" ":" date-time
                  connheader['date'] = cv[1]

                else
                  # Get error message
                  next if e.start_with?(' ', '-')
                  next unless e =~ Re1[:error]

                  # 500 User Unknown
                  # <kijitora@example.jp> Unknown
                  v['alterrors'] ||= ' '
                  v['alterrors']  << ' ' << e
                end
              end
            end
          end # End of if: rfc822

        end

        while true
          # Fallback, parse entire message body
          break if recipients > 0
          match = 0

          # Failed to get a recipient address at code above
          match += 1 if mhead['from']    =~ Re0[:from]
          match += 1 if mhead['subject'] =~ Re0[:subject]

          if mhead['return-path']
            # Check the value of Return-Path of the message
            match += 1 if mhead['return-path'] =~ Re0[:'return-path']
          end
          break unless match > 0

          re_skip = %r{(?>
             \A[-]+=
            |\A\s+\z
            |\A\s*--
            |\A\s+[=]\d+
            |\AHi[ ][!]
            |Content-(?:Description|Disposition|Transfer-Encoding|Type):[ ]
            |(?:name|charset)=
            |--\z
            |:[ ]--------
            )
          }xi
          re_stop = %r{(?:
             \A[*][*][*][ ].+[ ].+[ ][*][*][*]
            |\AContent-Type:[ ]message/delivery-status
            |\AHere[ ]is[ ]a[ ]copy[ ]of[ ]the[ ]first[ ]part[ ]of[ ]the[ ]message
            |\AThe[ ]non-delivered[ ]message[ ]is[ ]attached[ ]to[ ]this[ ]message.
            |\AReceived:[ \t]*
            |\AReceived-From-MTA:[ \t]*
            |\AReporting-MTA:[ \t]*
            |\AReturn-Path:[ \t]*
            |\AA[ ]copy[ ]of[ ]the[ ]original[ ]message[ ]below[ ]this[ ]line:
            |Attachment[ ]is[ ]a[ ]copy[ ]of[ ]the[ ]message
            |Below[ ]is[ ]a[ ]copy[ ]of[ ]the[ ]original[ ]message:
            |Below[ ]this[ ]line[ ]is[ ]a[ ]copy[ ]of[ ]the[ ]message
            |Message[ ]contains[ ].+[ ]file[ ]attachments
            |Message[ ]text[ ]follows:[ ]
            |Original[ ]message[ ]follows
            |The[ ]attachment[ ]contains[ ]the[ ]original[ ]mail[ ]headers
            |The[ ]first[ ]\d+[ ]lines[ ]
            |Unsent[ ]Message[ ]below
            |Your[ ]message[ ]reads[ ][(]in[ ]part[)]:
            )
          }xi
          re_addr = %r{(?:
             \A\s*
            |\A["].+["]\s*
            |\A[ \t]*Recipient:[ \t]*
            |\A[ ]*Address:[ ]
            |addressed[ ]to[ ]
            |Could[ ]not[ ]be[ ]delivered[ ]to:[ ]
            |delivered[ ]to[ ]+
            |delivery[ ]failed:[ ]
            |Did[ ]not[ ]reach[ ]the[ ]following[ ]recipient:[ ]
            |Error-for:[ ]+
            |Failed[ ]Recipient:[ ]
            |Failed[ ]to[ ]deliver[ ]to[ ]
            |Intended[ ]recipient:[ ]
            |Mailbox[ ]is[ ]full:[ ]
            |RCPT[ ]To:
            |SMTP[ ]Server[ ][<].+[>][ ]rejected[ ]recipient[ ]
            |The[ ]following[ ]recipients[ ]returned[ ]permanent[ ]errors:[ ]
            |The[ ]following[ ]message[ ]to[ ]
            |Unknown[ ]User:[ ]
            |undeliverable[ ]to[ ]
            |Undeliverable[ ]Address:[ ]*
            |You[ ]sent[ ]mail[ ]to[ ]
            |Your[ ]message[ ]to[ ]
            )
            ['"]?[<]?([^\s\n\r@=<>]+[@][-.0-9A-Za-z]+[.][0-9A-Za-z]+)[>]?['"]?
          }xi

          b = dscontents[-1]
          mbody.split("\n").each do |e|
            # Get the recipient's email address and error messages.
            break if e =~ Re1[:endof]
            break if e =~ Re1[:rfc822]
            break if e =~ re_stop

            next if e.size.zero?
            next if e =~ re_skip
            next if e.start_with?('*')

            if cv = e.match(re_addr)
              # May be an email address
              x = b['recipient'] || ''
              y = Sisimai::Address.s3s4(cv[1])
              next unless Sisimai::RFC5322.is_emailaddress(y)

              if x.size > 0 && x != y
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                b = dscontents[-1]
              end
              b['recipient'] = y
              b['agent'] = self.smtpagent + '::Fallback'
              recipients += 1

            elsif cv = e.match(/[(](?:expanded|generated)[ ]from:?[ ]([^@]+[@][^@]+)[)]/)
              # (expanded from: neko@example.jp)
              b['alias'] = Sisimai::Address.s3s4(cv[1])
            end
            b['diagnosis'] ||= ''
            b['diagnosis']  << ' ' << e
          end

          break
        end

        if recipients.zero?
          # Try to get a recipient address from email headers
          rfc822list.each do |e|
            # Check To: header in the original message
            next unless cv = e.match(/\ATo:\s*(.+)\z/)
            r = Sisimai::Address.find(cv[1], true) || []
            next if r.empty?

            if dscontents.size == recipients
              dscontents << Sisimai::Bite::Email.DELIVERYSTATUS
            end
            b = dscontents[-1]
            b['recipient'] = r[0][:address]
            b['agent'] = Sisimai::RFC3464.smtpagent + '::Fallback'
            recipients += 1
          end
        end

        return nil unless recipients > 0
        require 'sisimai/string'
        require 'sisimai/smtp/status'

        dscontents.map do |e|
          # Set default values if each value is empty.
          connheader.each_key { |a| e[a] ||= connheader[a] || '' }

          if e.key?('alterrors') && e['alterrors'].size > 0
            # Copy alternative error message
            e['diagnosis'] ||= e['alterrors']
            if e['diagnosis'].start_with?('-') || e['diagnosis'].end_with?('__')
              # Override the value of diagnostic code message
              e['diagnosis'] = e['alterrors'] if e['alterrors'].size > 0
            end
            e.delete('alterrors')
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''

          if scannedset
            # Make bounce data by the values returned from Sisimai::MDA->scan()
            e['agent']     = scannedset['mda'] || self.smtpagent
            e['reason']    = scannedset['reason'] || 'undefined'
            e['diagnosis'] = scannedset['message'] if scannedset['message'].size > 0
            e['command']   = ''

          else
            # Set the value of smtpagent
            e['agent'] = self.smtpagent
          end

          e['status'] ||= Sisimai::SMTP::Status.find(e['diagnosis'])
          if cv = e['diagnosis'].match(Re1[:command])
            e['command'] = cv[1]
          end
          e['date'] ||= mhead['date']
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end
