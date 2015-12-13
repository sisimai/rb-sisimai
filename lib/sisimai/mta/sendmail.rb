module Sisimai
  module MTA
    # Sisimai::MTA::Sendmail parses a bounce email which created by v8 Sendmail.
    # Methods in the module are called from only Sisimai::Message.
    module Sendmail
      # Imported from p5-Sisimail/lib/Sisimai/MTA/Sendmail.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :from    => %r/\AMail Delivery Subsystem/,
          :subject => %r/(?:see transcript for details\z|\AWarning: )/,
        }
        # Error text regular expressions which defined in sendmail/savemail.c
        #   savemail.c:1040|if (printheader && !putline("   ----- Transcript of session follows -----\n",
        #   savemail.c:1041|          mci))
        #   savemail.c:1042|  goto writeerr;
        #
        Re1 = {
          :begin   => %r/\A\s+[-]+ Transcript of session follows [-]+\z/,
          :error   => %r/\A[.]+ while talking to .+[:]\z/,
          :rfc822  => %r{\AContent-Type:[ ]*(?:message/rfc822|text/rfc822-headers)\z},
          :endof   => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        Indicators = Sisimai::MTA.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'V8Sendmail: /usr/sbin/sendmail'; end
        def smtpagent;   return 'Sendmail'; end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Detect an error from Sendmail
        # @param         [Hash] mhead       Message header of a bounce email
        # @options mhead [String] from      From header
        # @options mhead [String] date      Date header
        # @options mhead [String] subject   Subject header
        # @options mhead [Array]  received  Received headers
        # @options mhead [String] others    Other required headers
        # @param         [String] mbody     Message body of a bounce email
        # @return        [Hash, Undef]      Bounce data list and message/rfc822 part
        #                                   or Undef if it failed to parse or the
        #                                   arguments are missing
        def scan(mhead, mbody)
          return nil unless mhead
          return nil unless mbody
          return nil unless mhead['subject'] =~ Re0[:subject]

          unless mhead['subject'] =~ /\A\s*Fwd?:/i
            # Fwd: Returned mail: see transcript for details
            # Do not execute this code if the bounce mail is a forwarded message.
            return nil unless mhead['from'] =~ Re0[:from]
          end

          dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          havepassed = [''];
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          commandtxt = ''     # (String) SMTP Command name begin with the string '>>>'
          esmtpreply = ''     # (String) Reply from remote server on SMTP session
          sessionerr = false  # (Boolean) Flag, "true" if it is SMTP session error
          connvalues = 0      # (Integer) Flag, 1 if all the value of $connheader have been set
          connheader = {
            'date'  => '',    # The value of Arrival-Date header
            'rhost' => '',    # The value of Reporting-MTA header
          }
          anotherset = {}     # Another error information
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

              if connvalues == connheader.keys.size
                # Final-Recipient: RFC822; userunknown@example.jp
                # X-Actual-Recipient: RFC822; kijitora@example.co.jp
                # Action: failed
                # Status: 5.1.1
                # Remote-MTA: DNS; mx.example.jp
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
                v = dscontents[-1]

                if cv = e.match(/\A[Ff]inal-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                  # Final-Recipient: RFC822; userunknown@example.jp
                  if v['recipient']
                    # There are multiple recipient addresses in the message body.
                    dscontents << Sisimai::MTA.DELIVERYSTATUS
                    v = dscontents[-1]
                  end
                  v['recipient'] = cv[1]
                  recipients += 1

                elsif cv = e.match(/\A[Xx]-[Aa]ctual-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
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
                    # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                    v['spec'] = cv[1].upcase
                    v['diagnosis'] = cv[2]

                  elsif p =~ /\A[Dd]iagnostic-[Cc]ode:[ ]*/ && cv = e.match(/\A\s+(.+)\z/)
                    # Continued line of the value of Diagnostic-Code header
                    v['diagnosis'] ||= ''
                    v['diagnosis']  += ' ' + cv[1]
                  end
                end

              else
                # ----- Transcript of session follows -----
                # ... while talking to mta.example.org.:
                # >>> DATA
                # <<< 550 Unknown user recipient@example.jp
                # 554 5.0.0 Service unavailable
                # ...
                # Reporting-MTA: dns; mx.example.jp
                # Received-From-MTA: DNS; x1x2x3x4.dhcp.example.ne.jp
                # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                if cv = e.match(/\A[>]{3}[ ]+([A-Z]{4})[ ]?/)
                  # >>> DATA
                  commandtxt = cv[1]

                elsif cv = e.match(/\A[<]{3}[ ]+(.+)\z/)
                  # <<< Response
                  esmtpreply = cv[1]

                elsif cv = e.match(/\A[Rr]eporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Reporting-MTA: dns; mx.example.jp
                  next if connheader['rhost'].size > 0
                  connheader['rhost'] = cv[1]
                  connvalues += 1

                elsif cv = e.match(/\A[Rr]eceived-[Ff]rom-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Received-From-MTA: DNS; x1x2x3x4.dhcp.example.ne.jp
                  next if connheader['lhost']

                  # The value of "lhost" is optional
                  connheader['lhost'] = cv[1]
                  connvalues += 1

                elsif cv = e.match(/\A[Aa]rrival-[Dd]ate:[ ]*(.+)\z/)
                  # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                  next if connheader['date'].size > 0
                  connheader['date'] = cv[1]
                  connvalues += 1

                else
                  # Detect SMTP session error or connection error
                  next if sessionerr
                  if e =~ Re1[:error]
                    # ----- Transcript of session follows -----
                    # ... while talking to mta.example.org.:
                    sessionerr = true
                    next
                  end

                  if cv = e.match(/\A[<](.+)[>][.]+ (.+)\z/)
                    # <kijitora@example.co.jp>... Deferred: Name server: example.co.jp.: host name lookup failure
                    anotherset['recipient'] = cv[1]
                    anotherset['diagnosis'] = cv[2]

                  else
                    # ----- Transcript of session follows -----
                    # Message could not be delivered for too long
                    # Message will be deleted from queue
                    next if e =~ /\A\s*[-]+/
                    if cv = e.match(/\A[45]\d\d\s([45][.]\d[.]\d)\s.+/)
                      # 550 5.1.2 <kijitora@example.org>... Message
                      #
                      # DBI connect('dbname=...')
                      # 554 5.3.0 unknown mailer error 255
                      anotherset['status'] = cv[1]
                      anotherset['diagnosis'] ||= ''
                      anotherset['diagnosis']  += ' ' + e

                    elsif e =~ /\A(?:Message|Warning:) /
                      # Message could not be delivered for too long
                      # Warning: message still undelivered after 4 hours
                      anotherset['diagnosis'] ||= ''
                      anotherset['diagnosis'] += ' ' + e
                    end
                  end
                end
              end
            end

          end

          return nil unless recipients > 0
          require 'sisimai/string'

          dscontents.map do |e|
            # Set default values if each value is empty.
            connheader.each_key { |a| e[a] ||= connheader[a] || '' }

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r = mhead['received']
              e['lhost'] ||= Sisimai::RFC5322.received(r[0]).shift
              e['rhost'] ||= Sisimai::RFC5322.received(r[-1]).pop
            end

            e['spec']    ||= 'SMTP'
            e['agent']     = self.smtpagent
            e['command'] ||= commandtxt || ''
            e['command'] ||= 'EHLO' if esmtpreply.size > 0

            if anotherset['diagnosis']
              # Copy alternative error message
              e['diagnosis'] = anotherset['diagnosis'] if e['diagnosis'] =~ /\A\s+\z/
              e['diagnosis'] = anotherset['diagnosis'] unless e['diagnosis']

              if e['diagnosis'] =~ /\A\d+\z/
                # Override the value of diagnostic code message
                e['diagnosis'] = anotherset['diagnosis']
              end
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            if anotherset['status']
              # Check alternative status code
              if e['status'].empty? || e['status'] !~ /\A[45][.]\d[.]\d\z/
                # Override alternative status code
                e['status'] = anotherset['status']
              end
            end

            unless e['recipient'] =~ /\A[^ ]+[@][^ ]+\z/
              # @example.jp, no local part
              if cv = e['diagnosis'].match(/[<]([^ ]+[@][^ ]+)[>]/)
                # Get email address from the value of Diagnostic-Code header
                e['recipient'] = cv[1]
              end
            end

          end
          return { 'ds' => dscontents, 'rfc822' => rfc822part }

        end

      end
    end
  end
end
