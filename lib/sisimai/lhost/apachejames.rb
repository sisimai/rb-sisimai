module Sisimai::Lhost
  # Sisimai::Lhost::ApacheJames decodes a bounce email which created by ApacheJames https://james.apache.org/.
  # Methods in the module are called from only Sisimai::Message.
  module ApacheJames
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ["Content-Type: message/rfc822"].freeze
      StartingOf = {
        # apache-james-2.3.2/src/java/org/apache/james/transport/mailets/
        #   AbstractNotify.java|124:  out.println("Error message below:");
        #   AbstractNotify.java|128:  out.println("Message details:");
        message: ["Message details:"],
      }.freeze

      # @abstract decodes the bounce message from Apache James
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        match  = 0
        match += 1 if mhead["subject"] == "[BOUNCE]"
        match += 1 if mhead["message-id"].to_s.include?(".JavaMail.")
        match += 1 if mhead["received"].any? { |a| a.include?("JAMES SMTP Server") }
        return nil if match == 0

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]; v = dscontents[-1]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readcursor = 0                # Points the current cursor position
        recipients = 0                # The number of 'Final-Recipient' header
        alternates = ["", "", "", ""] # [Envelope-From, Header-From, Date, Subject]

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e.start_with?(StartingOf[:message][0])
              # Message details:
              #   Subject: Nyaaan
              readcursor |= Indicators[:deliverystatus]
              next
            end
            v["diagnosis"] += "#{e }" if e != ""
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0 || e.empty?

          # Message details:
          #   Subject: Nyaaan
          #   Sent date: Thu Apr 29 01:20:50 JST 2015
          #   MAIL FROM: shironeko@example.jp
          #   RCPT TO: kijitora@example.org
          #   From: Neko <shironeko@example.jp>
          #   To: kijitora@example.org
          #   Size (in bytes): 1024
          #   Number of lines: 64
          if e.start_with?("  RCPT TO: ")
            #   RCPT TO: kijitora@example.org
            if v["recipient"] != ""
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v["recipient"] = e[12, e.size]
            recipients += 1

          elsif e.start_with?("  Sent date: ")
            #   Sent date: Thu Apr 29 01:20:50 JST 2015
            v["date"]     = e[13, e.size]
            alternates[2] = v["date"]

          elsif e.start_with?("  Subject: ")
            #   Subject: Nyaaan
            alternates[3] = e[11, e.size]

          elsif e.start_with?("  MAIL FROM: ")
            #   MAIL FROM: shironeko@example.jp
            alternates[0] = e[13, e.size]

          elsif e.start_with?("  From: ")
            #   From: Neko <shironeko@example.jp>
            alternates[1] = e[8, e.size]

          end
        end
        return nil if recipients == 0

        if emailparts[1].empty?
          # The original message is empty
          emailparts[1] += sprintf("From: %s\n", alternates[1]) if alternates[1] != ""
          emailparts[1] += sprintf("Date: %s\n", alternates[2]) if alternates[2] != ""
        end
        if emailparts[1].include?("Return-Path: ") == false
          # Set the envelope from address as a Return-Path: header
          emailparts[1] += sprintf("Return-Path: <%s>\n", alternates[0]) if alternates[0] != ""
        end
        if emailparts[1].include?("\nSubject: ") == false
          # Set the envelope from address as a Return-Path: header
          emailparts[1] += sprintf("Subject: %s\n", alternates[3]) if alternates[3] != ""
        end

        return { "ds" => dscontents, "rfc822" => emailparts[1] }
      end
      def description; return 'Java Apache Mail Enterprise Server'; end
    end
  end
end

