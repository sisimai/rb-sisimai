module Sisimai::Lhost
  # Sisimai::Lhost::Sendmail parses a bounce email which created by v8 Sendmail. Methods in the module
  # are called from only Sisimai::Message.
  module Sendmail
    class << self
      require 'sisimai/lhost'
      require 'sisimai/smtp/reply'
      require 'sisimai/smtp/status'
      require 'sisimai/smtp/command'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['Content-Type: message/rfc822', 'Content-Type: text/rfc822-headers'].freeze
      StartingOf = {
        # Error text regular expressions which defined in sendmail/savemail.c
        #   savemail.c:1040|if (printheader && !putline("   ----- Transcript of session follows -----\n",
        #   savemail.c:1041|          mci))
        #   savemail.c:1042|  goto writeerr;
        #   savemail.c:1360|if (!putline(
        #   savemail.c:1361|    sendbody
        #   savemail.c:1362|    ? "   ----- Original message follows -----\n"
        #   savemail.c:1363|    : "   ----- Message header follows -----\n",
        message: ['   ----- Transcript of session follows -----'],
        error:   ['... while talking to '],
      }.freeze

      # Parse bounce messages from Sendmail
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil if mhead['x-aol-ip']
        match   = nil
        match ||= true if mhead['subject'].end_with?('see transcript for details')
        match ||= true if mhead['subject'].start_with?('Warning: ')
        return nil unless match

        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readslices = ['']
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        thecommand = ''     # (String) SMTP Command name begin with the string '>>>'
        esmtpreply = []     # (Array) Reply from remote server on SMTP session
        sessionerr = false  # (Boolean) Flag, "true" if it is SMTP session error
        anotherset = {}     # Another error information
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          readslices << e # Save the current line for the next loop

          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          if f = Sisimai::RFC1894.match(e)
            # "e" matched with any field defined in RFC3464
            o = Sisimai::RFC1894.field(e) || next
            v = dscontents[-1]

            if o[-1] == 'addr'
              # Final-Recipient: rfc822; kijitora@example.jp
              # X-Actual-Recipient: rfc822; kijitora@example.co.jp
              if o[0] == 'final-recipient'
                # Final-Recipient: rfc822; kijitora@example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Lhost.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = o[2]
                recipients += 1
              else
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                v['alias'] = o[2]
              end
            elsif o[-1] == 'code'
              # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
              v['spec'] = o[1]
              v['diagnosis'] = o[2]
            else
              # Other DSN fields defined in RFC3464
              next unless fieldtable[o[0]]
              v[fieldtable[o[0]]] = o[2]

              next unless f
              permessage[fieldtable[o[0]]] = o[2]
            end
          else
            # The line does not begin with a DSN field defined in RFC3464
            #
            # ----- Transcript of session follows -----
            # ... while talking to mta.example.org.:
            # >>> DATA
            # <<< 550 Unknown user recipient@example.jp
            # 554 5.0.0 Service unavailable
            # ...
            # Reporting-MTA: dns; mx.example.jp
            # Received-From-MTA: DNS; x1x2x3x4.dhcp.example.ne.jp
            # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
            unless e.start_with?(' ')
              if e.start_with?('>>> ')
                # >>> DATA
                thecommand = Sisimai::SMTP::Command.find(e)

              elsif e.start_with?('<<< ')
                # <<< Response
                cv = e[4, e.size - 4]
                esmtpreply << cv unless esmtpreply.index(cv)
              else
                # Detect SMTP session error or connection error
                next if sessionerr
                if e.start_with?(StartingOf[:error][0])
                  # ----- Transcript of session follows -----
                  # ... while talking to mta.example.org.:
                  sessionerr = true
                  next
                end

                if e.start_with?('<') && Sisimai::String.aligned(e, ['@', '>.', ' '])
                  # <kijitora@example.co.jp>... Deferred: Name server: example.co.jp.: host name lookup failure
                  anotherset['recipient'] = Sisimai::Address.s3s4(e[0, e.index('>')])
                  anotherset['diagnosis'] = e[e.index(' ') + 1, e.size]
                else
                  # ----- Transcript of session follows -----
                  # Message could not be delivered for too long
                  # Message will be deleted from queue
                  cr = Sisimai::SMTP::Reply.find(e)  || ''
                  cs = Sisimai::SMTP::Status.find(e) || ''

                  if cr.size + cs.size > 7
                    # 550 5.1.2 <kijitora@example.org>... Message
                    #
                    # DBI connect('dbname=...')
                    # 554 5.3.0 unknown mailer error 255
                    anotherset['status']      = cs
                    anotherset['diagnosis'] ||= ''
                    anotherset['diagnosis'] << ' ' << e

                  elsif e.start_with?('Message ', 'Warning: ')
                    # Message could not be delivered for too long
                    # Warning: message still undelivered after 4 hours
                    anotherset['diagnosis'] ||= ''
                    anotherset['diagnosis'] << ' ' << e
                  end
                end
              end
            else
              # Continued line of the value of Diagnostic-Code field
              next unless readslices[-2].start_with?('Diagnostic-Code:')
              next unless e.start_with?(' ')
              v['diagnosis'] << ' ' << Sisimai::String.sweep(e)
              readslices[-1] = 'Diagnostic-Code: ' << e
            end
          end
        end # End of message/delivery-status
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          e['diagnosis'] ||= ''
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }

          if anotherset['diagnosis']
            # Copy alternative error message
            e['diagnosis'] = anotherset['diagnosis'] if e['diagnosis'].start_with?(' ')
            e['diagnosis'] = anotherset['diagnosis'] if e['diagnosis'].=~ /\A\d+\z/
            e['diagnosis'] = anotherset['diagnosis'] if e['diagnosis'].empty?
          end

          while true
            # Replace or append the error message in "diagnosis" with the ESMTP Reply Code when the
            # following conditions have matched
            break if esmtpreply.empty?
            break if recipients != 1

            e['diagnosis'] = sprintf("%s %s", esmtpreply.join(' '), e['diagnosis'])
            break
          end

          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['command'] ||= thecommand || Sisimai::SMTP::Command.find(e['diagnosis']) || ''
          if e['command'].empty?
            e['command'] = 'EHLO' unless esmtpreply.empty?
          end

          while true
            # Check alternative status code and override it
            break unless anotherset.has_key?('status')
            break unless anotherset['status'].size > 0
            break if     Sisimai::SMTP::Status.test(e['status'])

            e['status'] = anotherset['status']
            break
          end

          # @example.jp, no local part
          # # Get email address from the value of Diagnostic-Code field
          next unless e['recipient'].start_with?('@')
          cv = Sisimai::Address.find(e['diagnosis'], true) || []
          e['recipient'] = cv[0][:address] if cv.size > 0
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'V8Sendmail: /usr/sbin/sendmail'; end
    end
  end
end

