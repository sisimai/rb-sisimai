module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Postfix parses a bounce email which created by
  # Postfix. Methods in the module are called from only Sisimai::Message.
  module Postfix
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Postfix.pm
      require 'sisimai/bite/email'

      # Postfix manual - bounce(5) - http://www.postfix.org/bounce.5.html
      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = { rfc822: ['Content-Type: message/rfc822', 'Content-Type: text/rfc822-headers'] }.freeze
      MarkingsOf = {
        message: %r{\A(?>
           [ ]+The[ ](?:
             Postfix[ ](?:
               program\z              # The Postfix program
              |on[ ].+[ ]program\z    # The Postfix on <os name> program
              )
            |\w+[ ]Postfix[ ]program\z  # The <name> Postfix program
            |mail[ \t]system\z             # The mail system
            |\w+[ \t]program\z             # The <custmized-name> program
            )
          |This[ ]is[ ]the[ ](?:
             Postfix[ ]program          # This is the Postfix program
            |\w+[ ]Postfix[ ]program    # This is the <name> Postfix program
            |\w+[ ]program              # This is the <customized-name> Postfix program
            |mail[ ]system[ ]at[ ]host  # This is the mail system at host <hostname>.
            )
          )
        }x,
      }.freeze

      def description; return 'Postfix'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Postfix
      # @param         [Hash] mhead       Message headers of a bounce email
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
        # :from => %r/ [(]Mail Delivery System[)]\z/,
        return nil unless mhead['subject'] == 'Undelivered Mail Returned to Sender'

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        commandset = []     # (Array) ``in reply to * command'' list
        connvalues = 0      # (Integer) Flag, 1 if all the value of connheader have been set
        connheader = {
          'date'  => '',    # The value of Arrival-Date header
          'lhost' => '',    # The value of Received-From-MTA header
        }
        anotherset = {}     # Another error information
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e =~ MarkingsOf[:message]
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e.start_with?(StartingOf[:rfc822][0], StartingOf[:rfc822][1])
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
            next if (readcursor & Indicators[:deliverystatus]) == 0
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
              if cv = e.match(/\AFinal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*(.+)\z/)
                # Final-Recipient: RFC822; userunknown@example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Bite.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              elsif cv = e.match(/\AX-Actual-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/) ||
                         e.match(/\AOriginal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # X-Actual-Recipient: RFC822; kijitora@example.co.jp
                # Original-Recipient: rfc822;kijitora@example.co.jp
                v['alias'] = cv[1]

              elsif cv = e.match(/\AAction:[ ]*(.+)\z/)
                # Action: failed
                v['action'] = cv[1].downcase

              elsif cv = e.match(/\AStatus:[ ]*(\d[.]\d+[.]\d+)/)
                # Status: 5.1.1
                # Status:5.2.0
                # Status: 5.1.0 (permanent failure)
                v['status'] = cv[1]

              elsif cv = e.match(/\ARemote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Remote-MTA: DNS; mx.example.jp
                v['rhost'] = cv[1].downcase

              elsif cv = e.match(/\ALast-Attempt-Date:[ ]*(.+)\z/)
                # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
                #
                # src/bounce/bounce_notify_util.c:
                #   681  #if 0
                #   682      if (dsn->time > 0)
                #   683          post_mail_fprintf(bounce, "Last-Attempt-Date: %s",
                #   684                            mail_date(dsn->time));
                #   685  #endif
                v['date'] = cv[1]
              else
                if cv = e.match(/\ADiagnostic-Code:[ ]*(.+?);[ ]*(.*)\z/)
                  # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                  v['spec'] = cv[1].upcase
                  v['diagnosis'] = cv[2]
                  v['spec'] = 'SMTP' if v['spec'] == 'X-POSTFIX'

                elsif p.start_with?('Diagnostic-Code:') && cv = e.match(/\A[ \t]+(.+)\z/)
                  # Continued line of the value of Diagnostic-Code header
                  v['diagnosis'] << ' ' << cv[1]
                  havepassed[-1] = 'Diagnostic-Code: ' << e
                end
              end
            else
              # If you do so, please include this problem report. You can
              # delete your own text from the attached returned message.
              #
              #           The mail system
              #
              # <userunknown@example.co.jp>: host mx.example.co.jp[192.0.2.153] said: 550
              # 5.1.1 <userunknown@example.co.jp>... User Unknown (in reply to RCPT TO
              # command)
              if cv = e.match(/[ \t][(]in reply to ([A-Z]{4}).*/)
                # 5.1.1 <userunknown@example.co.jp>... User Unknown (in reply to RCPT TO
                commandset << cv[1]
                anotherset['diagnosis'] ||= ''
                anotherset['diagnosis'] << ' ' << e

              elsif cv = e.match(/([A-Z]{4})[ \t]*.*command[)]\z/)
                # to MAIL command)
                commandset << cv[1]
                anotherset['diagnosis'] ||= ''
                anotherset['diagnosis'] << ' ' << e

              else
                if cv = e.match(/\AReporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Reporting-MTA: dns; mx.example.jp
                  next unless connheader['lhost'].empty?
                  connheader['lhost'] = cv[1].downcase
                  connvalues += 1

                elsif cv = e.match(/\AArrival-Date:[ ]*(.+)\z/)
                  # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                  next unless connheader['date'].empty?
                  connheader['date'] = cv[1]
                  connvalues += 1

                elsif cv = e.match(/\A(X-Postfix-Sender):[ ]*rfc822;[ ]*(.+)\z/)
                  # X-Postfix-Sender: rfc822; shironeko@example.org
                  rfc822list << (cv[1] << ': ' << cv[2])
                else
                  # Alternative error message and recipient
                  if cv = e.match(/\A[<]([^ ]+[@][^ ]+)[>] [(]expanded from [<](.+)[>][)]:[ \t]*(.+)\z/)
                    # <r@example.ne.jp> (expanded from <kijitora@example.org>): user ...
                    anotherset['recipient'] = cv[1]
                    anotherset['alias']     = cv[2]
                    anotherset['diagnosis'] = cv[3]

                  elsif cv = e.match(/\A[<]([^ ]+[@][^ ]+)[>]:(.*)\z/)
                    # <kijitora@exmaple.jp>: ...
                    anotherset['recipient'] = cv[1]
                    anotherset['diagnosis'] = cv[2]
                  else
                    # Get error message continued from the previous line
                    next unless anotherset['diagnosis']
                    if e =~ /\A[ \t]{4}(.+)\z/
                      #    host mx.example.jp said:...
                      anotherset['diagnosis'] << ' ' << e
                    end
                  end
                end
              end
            end
          end # End of if: rfc822
        end

        unless recipients > 0
          # Fallback: set recipient address from error message
          unless anotherset['recipient'].to_s.empty?
            # Set recipient address
            dscontents[-1]['recipient'] = anotherset['recipient']
            recipients += 1
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          connheader.each_key { |a| e[a] ||= connheader[a] || '' }

          e['agent']   = self.smtpagent
          e['command'] = commandset.shift || ''

          if anotherset['diagnosis']
            # Copy alternative error message
            e['diagnosis'] = anotherset['diagnosis'] unless e['diagnosis']

            if e['diagnosis'] =~ /\A\d+\z/
              e['diagnosis'] = anotherset['diagnosis']
            else
              # More detailed error message is in "anotherset"
              as = nil  # status
              ar = nil  # replycode

              e['status']    ||= ''
              e['replycode'] ||= ''

              if e['status'] == '' || e['status'].start_with?('4.0.0', '5.0.0')
                # Check the value of D.S.N. in anotherset
                as = Sisimai::SMTP::Status.find(anotherset['diagnosis'])
                if !as.empty? && as[-3, 3] != '0.0'
                  # The D.S.N. is neither an empty nor *.0.0
                  e['status'] = as
                end
              end

              if e['replycode'] == '' || e['replycode'].start_with?('400', '500')
                # Check the value of SMTP reply code in anotherset
                ar = Sisimai::SMTP::Reply.find(anotherset['diagnosis'])
                if !ar.empty? && ar[-2, 2].to_i != 0
                  # The SMTP reply code is neither an empty nor *00
                  e['replycode'] = ar
                end
              end

              if (as || ar) && (anotherset['diagnosis'].size > e['diagnosis'].size)
                # Update the error message in e['diagnosis']
                e['diagnosis'] = anotherset['diagnosis']
              end
            end
          end

          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['spec']    ||= 'SMTP' if e['diagnosis'] =~ /host .+ said:/
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

