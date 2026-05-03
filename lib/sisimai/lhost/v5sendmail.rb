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
        error:   ['While talking to '],
        message: ['----- Transcript of session follows -----'],
      }.freeze

      # @abstract Decodes the bounce message from Sendmail version 5
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        # :from => %r/\AMail Delivery Subsystem/,
        return nil if mhead['subject'].start_with?('Returned mail: ') == false

        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        return nil if emailparts[1].size == 0

        require 'sisimai/rfc1123'
        require 'sisimai/smtp/command'
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]; v = nil
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        anotherone = {}     # (Hash) Another error information
        remotehost = ""     # The last remote hostname
        curcommand = ""     # The last SMTP command

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.include?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0 || e.empty?

          #    ----- Transcript of session follows -----
          # While talking to smtp.example.com:
          # >>> RCPT To:<kijitora@example.org>
          # <<< 550 <kijitora@example.org>, User Unknown
          # 550 <kijitora@example.org>... User unknown
          # 421 example.org (smtp)... Deferred: Connection timed out during user open with example.org
          v = dscontents[-1]
          curcommand = Sisimai::SMTP::Command.find(e) if e.start_with?(">>> ")

          if Sisimai::String.aligned(e, [' <', '@', '>...']) || e.upcase.include?(">>> RCPT TO:")
            # 550 <kijitora@example.org>... User unknown
            # >>> RCPT To:<kijitora@example.org>
            p0 = e.index(" ")
            p1 = e.index("<", p0)
            p2 = e.index(">", p1)
            cv = Sisimai::Address.s3s4(e[p1, p2 - p1 + 1])

            if remotehost == ""
              # Keep error messages before "While talking to ..." line
              anotherone[recipients] ||= ""; anotherone[recipients] += " #{e}"
              next
            end

            if cv == v["recipient"] || (curcommand == "MAIL" && e.start_with?("<<< "))
              # The recipient address is the same address with the last appeared address
              # like "550 <mikeneko@example.co.jp>... User unknown"
              # Append this line to the string which is keeping error messages
              v["diagnosis"] += " #{e}"
              v["replycode"]  = Sisimai::SMTP::Reply.find(e)
              curcommand      = ""
            else
              # The recipient address in this line differs from the last appeared address
              # or is the first recipient address in this bounce message
              if v["recipient"] != ""
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                v = dscontents[-1]
              end
              recipients     += 1
              v["recipient"]  = cv
              v["rhost"]      = remotehost
              v["replycode"]  = Sisimai::SMTP::Reply.find(e)
              v["diagnosis"] += " #{e}"
              v["command"]    = curcommand if v["command"].empty?
            end
          else
            # This line does not include a recipient address
            if e.include?(StartingOf[:error][0])
              # ... while talking to mta.example.org.:
              cv = Sisimai::RFC1123.find(e)
              remotehost = cv if Sisimai::RFC1123.is_internethost(cv)
            else
              # Append this line into the error message string
              if e.start_with?(">>> ", "<<< ")
                # >>> DATA
                # <<< 550 Your E-Mail is redundant.  You cannot send E-Mail to yourself (shironeko@example.jp).
                # >>> QUIT
                # <<< 421 dns.example.org Sorry, unable to contact destination SMTP daemon.
                # <<< 550 Requested User Mailbox not found. No such user here.
                v["diagnosis"] += " #{e}"
              else
                # 421 Other error message
                anotherone[recipients] ||= ""; anotherone[recipients] += " #{e}"
              end
            end
          end
        end

        if recipients == 0
          # There is no recipient address in the error message
          anotherone.each_key do |e|
            # Try to pick an recipient address, a reply code, and error messages
            cv = Sisimai::Address.s3s4(anotherone[e]); next if Sisimai::Address.is_emailaddress(cv) == false
            cr = Sisimai::SMTP::Reply.find(anotherone[e])

            dscontents[e]["recipient"] = cv
            dscontents[e]["replycode"] = cr
            dscontents[e]["diagnosis"] = anotherone[e]
            recipients += 1
          end

          if recipients == 0
            # Try to pick an recipient address from the original message
            p1 = emailparts[1].index("\nTo: ")     || -1
            p2 = emailparts[1].index("\n", p1 + 6) || -1

            if p1 > 0
              # Get the recipient address from "To:" header at the original message
              cv = Sisimai::Address.s3s4(emailparts[1][p1, p2 - p1 - 5])
              return nil if Sisimai::Address.is_emailaddress(cv) == false
              dscontents[0]["recipient"] = cv
              recipients += 1
            end
          end
        end
        return nil if recipients == 0

        j = 0; dscontents.each do |e|
          # Tidy up the error message in e.Diagnosis
          e["diagnosis"] = anotherone[j] if e["diagnosis"].empty?
          e["command"]   = Sisimai::SMTP::Command.find(e["diagnosis"]) if e["command"].empty?
          e["replycode"] = Sisimai::SMTP::Reply.find(e["diagnosis"])
          e["replycode"] = Sisimai::SMTP::Reply.find(anotherone[j]) if e["replycode"].empty?

          # @example.jp, no local part
          # Get email address from the value of Diagnostic-Code header
          next if e['recipient'].include?('@')
          p1 = e['diagnosis'].index('<'); next if p1.nil?
          p2 = e['diagnosis'].index('>'); next if p2.nil?
          e['recipient'] = Sisimai::Address.s3s4(e[p1, p2 - p1])
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Sendmail version 5'; end
    end
  end
end

