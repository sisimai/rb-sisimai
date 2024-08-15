module Sisimai::Lhost
  # Sisimai::Lhost::Postfix decodes a bounce email which created by Postfix https://www.postfix.org/.
  # Methods in the module are called from only Sisimai::Message.
  module Postfix
    class << self
      require 'sisimai/lhost'
      require 'sisimai/smtp/command'

      # Postfix manual - bounce(5) - http://www.postfix.org/bounce.5.html
      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['Content-Type: message/rfc822', 'Content-Type: text/rfc822-headers'].freeze
      StartingOf = {
        # Postfix manual - bounce(5) - http://www.postfix.org/bounce.5.html
        message: [
          ['The ', 'Postfix '],           # The Postfix program, The Postfix on <os> program
          ['The ', 'mail system'],        # The mail system
          ['The ', 'program'],            # The <name> pogram
          ['This is the', 'Postfix'],     # This is the Postfix program
          ['This is the', 'mail system'], # This is the mail system at host <hostname>
        ],
      }.freeze

      # @abstract Decodes the bounce message from Postfix
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        match = 0

        if mhead['subject'].include?('SMTP server: errors from ')
          # src/smtpd/smtpd_chat.c:|337: post_mail_fprintf(notice, "Subject: %s SMTP server: errors from %s",
          # src/smtpd/smtpd_chat.c:|338:   var_mail_name, state->namaddr);
          match = 2
        else
          # Subject: Undelivered Mail Returned to Sender
          match = 1 if mhead['subject'] == 'Undelivered Mail Returned to Sender'
        end
        return nil if match == 0
        return nil if mhead['x-aol-ip']

        permessage = {}     # (Hash) Store values of each Per-Message field
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readslices = ['']
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        nomessages = false  # (Boolean) Delivery report unavailable
        commandset = []     # (Array) ``in reply to * command'' list
        anotherset = {}     # Another error information
        v = nil

        if match == 2
          # The message body starts with 'Transcript of session follows.'
          require 'sisimai/smtp/transcript'
          transcript = Sisimai::SMTP::Transcript.rise(emailparts[0], 'In:', 'Out:')

          return nil unless transcript
          return nil if transcript.size == 0

          transcript.each do |e|
            # Pick email addresses, error messages, and the last SMTP command.
            v ||= dscontents[-1]
            p   = e['response']

            if e['command'] == 'HELO' || e['command'] == 'EHLO'
              # Use the argument of EHLO/HELO command as a value of "lhost"
              v['lhost'] = e['argument']

            elsif e['command'] == 'MAIL'
              # Set the argument of "MAIL" command to pseudo To: header of the original message
              emailparts[1] += sprintf("To: %s\n", e['argument']) if emailparts[1].size == 0

            elsif e['command'] == 'RCPT'
              # RCPT TO: <...>
              if v['recipient']
                # There are multiple recipient addresses in the transcript of session
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = e['argument']
              recipients += 1
            end

            next if p['reply'].to_i < 400
            commandset << e['command']
            v['diagnosis'] ||= p['text'].join(' ')
            v['replycode'] ||= p['reply']
            v['status']    ||= p['status']
          end
        else
          fieldtable = Sisimai::RFC1894.FIELDTABLE
          readcursor = 0      # (Integer) Points the current cursor position

          while e = bodyslices.shift do
            # Read error messages and delivery status lines from the head of the email to the previous
            # line of the beginning of the original message.
            readslices << e # Save the current line for the next loop

            if readcursor == 0
              # Beginning of the bounce message or message/delivery-status part
              readcursor |= Indicators[:deliverystatus] if StartingOf[:message].any? { |a| Sisimai::String.aligned(e, a) }
              next
            end
            next if (readcursor & Indicators[:deliverystatus]) == 0
            next if e.empty?

            if f = Sisimai::RFC1894.match(e)
              # "e" matched with any field defined in RFC3464
              next unless o = Sisimai::RFC1894.field(e)
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
                v['spec'] = 'SMTP' if v['spec'].upcase == 'X-POSTFIX'
                v['diagnosis'] = o[2]
              else
                # Other DSN fields defined in RFC3464
                next unless fieldtable[o[0]]
                v[fieldtable[o[0]]] = o[2]

                next unless f
                permessage[fieldtable[o[0]]] = o[2]
              end
            else
              # If you do so, please include this problem report. You can
              # delete your own text from the attached returned message.
              #
              #           The mail system
              #
              # <userunknown@example.co.jp>: host mx.example.co.jp[192.0.2.153] said: 550
              # 5.1.1 <userunknown@example.co.jp>... User Unknown (in reply to RCPT TO command)
              if readslices[-2].start_with?('Diagnostic-Code:') && e.include?(' ')
                # Continued line of the value of Diagnostic-Code header
                v['diagnosis'] << ' ' << Sisimai::String.sweep(e)
                readslices[-1] = 'Diagnostic-Code: ' << e

              elsif Sisimai::String.aligned(e, ['X-Postfix-Sender:', 'rfc822;', '@'])
                # X-Postfix-Sender: rfc822; shironeko@example.org
                emailparts[1] << 'X-Postfix-Sender: ' << Sisimai::Address.s3s4(e[e.index(';') + 1, e.size]) << "\n"

              else
                # Alternative error message and recipient
                if e.include?(' (in reply to ') || e.include?('command)')
                  # 5.1.1 <userunknown@example.co.jp>... User Unknown (in reply to RCPT TO
                  q = Sisimai::SMTP::Command.find(e); commandset << q if q
                  anotherset['diagnosis'] ||= ''
                  anotherset['diagnosis'] << ' ' << e

                elsif Sisimai::String.aligned(e, ['<', '@', '>', '(expanded from<', '):'])
                  # <r@example.ne.jp> (expanded from <kijitora@example.org>): user ...
                  p1 = e.index('> ')
                  p2 = e.index('(expanded from ', p1)
                  p3 = e.index('>): ', p2 + 14)
                  anotherset['recipient'] = Sisimai::Address.s3s4(e[0, p1])
                  anotherset['alias']     = Sisimai::Address.s3s4(e[p2 + 15, p3 - p2 - 15])
                  anotherset['diagnosis'] = e[p3 + 3, e.size]

                elsif e.start_with?('<') && Sisimai::String.aligned(e, ['<', '@', '>:'])
                  # <kijitora@exmaple.jp>: ...
                  anotherset['recipient'] = Sisimai::Address.s3s4(e[0, e.index('>')])
                  anotherset['diagnosis'] = e[e.index('>:') + 2, e.size]

                elsif e.include?('--- Delivery report unavailable ---')
                  # postfix-3.1.4/src/bounce/bounce_notify_util.c
                  # bounce_notify_util.c:602|if (bounce_info->log_handle == 0
                  # bounce_notify_util.c:602||| bounce_log_rewind(bounce_info->log_handle)) {
                  # bounce_notify_util.c:602|if (IS_FAILURE_TEMPLATE(bounce_info->template)) {
                  # bounce_notify_util.c:602|    post_mail_fputs(bounce, "");
                  # bounce_notify_util.c:602|    post_mail_fputs(bounce, "\t--- delivery report unavailable ---");
                  # bounce_notify_util.c:602|    count = 1;              /* xxx don't abort */
                  # bounce_notify_util.c:602|}
                  # bounce_notify_util.c:602|} else {
                  nomessages = true
                else
                  # Get an error message continued from the previous line
                  next unless anotherset['diagnosis']
                  if e.start_with?('    ')
                    #    host mx.example.jp said:...
                    anotherset['diagnosis'] << ' ' << e[4, e.size]
                  end
                end
              end
            end
          end # end of while()

        end

        unless recipients > 0
          # Fallback: get a recipient address from error messages
          if anotherset['recipient'].to_s.size > 0
            # Set a recipient address
            dscontents[-1]['recipient'] = anotherset['recipient']
            recipients += 1
          else
            # Get a recipient address from message/rfc822 part if the delivery report was unavailable:
            # '--- Delivery report unavailable ---'
            p1 = emailparts[1].index("\nTo: ")     || -1
            p2 = emailparts[1].index("\n", p1 + 6) || -1
            if nomessages && p1 > 0
              # Try to get a recipient address from To: field in the original message at message/rfc822 part
              dscontents[-1]['recipient'] = Sisimai::Address.s3s4(emailparts[1][p1 + 5, p2 - p1 - 5])
              recipients += 1
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }

          if anotherset['diagnosis']
            # Copy alternative error message
            anotherset['diagnosis'] = Sisimai::String.sweep(anotherset['diagnosis'])
            e['diagnosis'] = anotherset['diagnosis'] if e['diagnosis'].nil? || e['diagnosis'].empty?

            if e['diagnosis'] =~ /\A\d+\z/
              # Override the value of diagnostic code message
              e['diagnosis'] = anotherset['diagnosis']
            else
              # More detailed error message is in "anotherset"
              as = '' # status
              ar = '' # replycode

              e['status']    ||= ''
              e['replycode'] ||= ''

              if e['status'].empty? || e['status'].start_with?('4.0.0', '5.0.0')
                # Check the value of D.S.N. in anotherset
                as = Sisimai::SMTP::Status.find(anotherset['diagnosis']) || ''
                if as.size > 0 && as[-4, 4] != '.0.0'
                  # The D.S.N. is neither an empty nor *.0.0
                  e['status'] = as
                end
              end

              if e['replycode'].empty? || e['replycode'].end_with?('00')
                # Check the value of SMTP reply code in $anotherset
                ar = Sisimai::SMTP::Reply.find(anotherset['diagnosis']) || ''
                if ar.size > 0 && ar.end_with?('00') == false
                  # The SMTP reply code is neither an empty nor *00
                  e['replycode'] = ar
                end
              end

              while true
                # Replace e['diagnosis'] with the value of anotherset['diagnosis'] when all the
                # following conditions have not matched.
                break if (as + ar).size == 0
                break if anotherset['diagnosis'].size < e['diagnosis'].size
                break if anotherset['diagnosis'].include?(e['diagnosis']) == false

                e['diagnosis'] = anotherset['diagnosis']
                break
              end
            end
          end

          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''
          e['command']   = commandset.shift || Sisimai::SMTP::Command.find(e['diagnosis'])
          e['command'] ||= 'HELO' if e['diagnosis'].include?('refused to talk to me:')
          e['spec']    ||= 'SMTP' if Sisimai::String.aligned(e['diagnosis'], ['host ', ' said:'])
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Postfix'; end
    end
  end
end

