module Sisimai::Lhost
  # Sisimai::Lhost::V5sendmail decodes a bounce email which created by Sendmail version 5 or any
  # email appliances based on Sendmail version 5.
  # Methods in the module are called from only Sisimai::Message.
  module V5sendmail
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['   ----- Unsent message follows -----', '  ----- No message was collected -----'].freeze
      StartingOf = {
        # Error text regular expressions which defined in src/savemail.c
        #   savemail.c:485| (void) fflush(stdout);
        #   savemail.c:486| p = queuename(e->e_parent, 'x');
        #   savemail.c:487| if ((xfile = fopen(p, "r")) == NULL)
        #   savemail.c:488| {
        #   savemail.c:489|   syserr("Cannot open %s", p);
        #   savemail.c:490|   fprintf(fp, "  ----- Transcript of session is unavailable -----\n");
        #   savemail.c:491| }
        #   savemail.c:492| else
        #   savemail.c:493| {
        #   savemail.c:494|   fprintf(fp, "   ----- Transcript of session follows -----\n");
        #   savemail.c:495|   if (e->e_xfp != NULL)
        #   savemail.c:496|       (void) fflush(e->e_xfp);
        #   savemail.c:497|   while (fgets(buf, sizeof buf, xfile) != NULL)
        #   savemail.c:498|       putline(buf, fp, m);
        #   savemail.c:499|   (void) fclose(xfile);
        error:   [' while talking to '],
        message: ['----- Transcript of session follows -----'],
      }.freeze

      # @abstract Decodes the bounce message from Sendmail version 5
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        # :from => %r/\AMail Delivery Subsystem/,
        return nil unless mhead['subject'].start_with?('Returned mail: ')

        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        return nil unless emailparts[1].size > 0

        require 'sisimai/smtp/command'
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        anotherset = {}     # (Hash) Another error information
        responding = []     # (Array) Responses from remote server
        commandset = []     # (Array) SMTP command which is sent to remote server
        errorindex = -1     # (Integer)
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.include?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          #    ----- Transcript of session follows -----
          # While talking to smtp.example.com:
          # >>> RCPT To:<kijitora@example.org>
          # <<< 550 <kijitora@example.org>, User Unknown
          # 550 <kijitora@example.org>... User unknown
          # 421 example.org (smtp)... Deferred: Connection timed out during user open with example.org
          v = dscontents[-1]

          if e.start_with?('5', '4') && Sisimai::String.aligned(e, [' <', '@', '>...'])
            # 550 <kijitora@example.org>... User unknown
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            p1 = e.index('<', 0)
            p2 = e.index('>...')
            v['recipient'] = e[p1 + 1, p2 - p1 - 1]
            v['diagnosis'] = e[p2 + 5, e.size]

            # Concatenate the response of the server and error message
            v['diagnosis'] << ': ' << responding[recipients] if responding[recipients]
            recipients += 1

          elsif e.start_with?('>>> ')
            # >>> RCPT To:<kijitora@example.org>
            cv = Sisimai::SMTP::Command.find(e); commandset[recipients] = cv if cv

          elsif e.start_with?('<<< ')
            # <<< Response
            # <<< 501 <shironeko@example.co.jp>... no access from mail server [192.0.2.55] which is an open relay.
            # <<< 550 Requested User Mailbox not found. No such user here.
            responding[recipients] = e[4, e.size]

          else
            # Detect SMTP session error or connection error
            next if v['sessionerr']

            if e.include?(StartingOf[:error][0])
              # ----- Transcript of session follows -----
              # ... while talking to mta.example.org.:
              v['sessionerr'] = true
              next
            end

            if e.start_with?('4', '5') && e.include?('... ')
              # 421 example.org (smtp)... Deferred: Connection timed out during user open with example.org
              anotherset['replycode'] = e[0, 3]
              anotherset['diagnosis'] = e[e.index('... ') + 4, e.size]
            end
          end
        end

        p1 = emailparts[1].index("\nTo: ")     || -1
        p2 = emailparts[1].index("\n", p1 + 6) || -1
        if recipients == 0 && p1 > 0
          # Get the recipient address from "To:" header at the original message
          dscontents[0]['recipient'] = Sisimai::Address.s3s4(emailparts[1][p1, p2 - p1 - 5])
          recipients = 1
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          errorindex += 1
          e.delete('sessionerr')

          e['diagnosis'] ||= if anotherset['diagnosis'].to_s.size > 0
                               # Copy alternative error message
                               anotherset['diagnosis']
                             else
                               # Set server response as a error message
                               responding[errorindex]
                             end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['replycode'] = Sisimai::SMTP::Reply.find(e['diagnosis']) || anotherset['replycode']
          e['command']   = commandset[errorindex] || Sisimai::SMTP::Command.find(e['diagnosis']) || ''

          # @example.jp, no local part
          # Get email address from the value of Diagnostic-Code header
          next if e['recipient'].include?('@')
          p1 = e['diagnosis'].index('<'); next unless p1
          p2 = e['diagnosis'].index('>'); next unless p2
          e['recipient'] = Sisimai::Address.s3s4(e[p1, p2 - p1])
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Sendmail version 5'; end
    end
  end
end

