module Sisimai::Lhost
  # Sisimai::Lhost::Qmail decodes a bounce email which created by qmail https://cr.yp.to/qmail.html
  # or qmail clones or notqmail https://notqmail.org/.
  # Methods in the module are called from only Sisimai::Message.
  module Qmail
    class << self
      require 'sisimai/eb'
      require 'sisimai/lhost'
      require 'sisimai/string'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = [
        # qmail-send.c:qmail_puts(&qqt,*sender.s ? "--- Below this line is a copy of the message.\n\n" :...
        "--- Below this line is a copy of the message.",     # qmail-1.03
        "--- Below this line is a copy of the mail header.",
        "--- Below the next line is a copy of the message.", # The followings are the qmail clone
        "--- Mensaje original adjunto.",
        "Content-Type: message/rfc822",
        "Original message follows.",
      ].freeze
      EmailTitle = [
        "failure notice", # qmail-send.c:Subject: failure notice\n\
        "Failure Notice", # Yahoo
      ].freeze
      StartingOf = {
        #  qmail-remote.c:248|    if (code >= 500) {
        #  qmail-remote.c:249|      out("h"); outhost(); out(" does not like recipient.\n");
        #  qmail-remote.c:265|  if (code >= 500) quit("D"," failed on DATA command");
        #  qmail-remote.c:271|  if (code >= 500) quit("D"," failed after I sent the message");
        #
        # Characters: K,Z,D in qmail-qmqpc.c, qmail-send.c, qmail-rspawn.c
        #  K = success, Z = temporary error, D = permanent error
        "error"   => ["Remote host said:"],
        "message" => [
          "Hi. This is the qmail", # qmail-send.c:Hi. This is the qmail-send program at ");
          "He/Her is not ",        # The followings are the qmail clone
          "unable to deliver your message to the following addresses",
          "Su mensaje no pudo ser entregado",
          "Sorry, we were unable to deliver your message to the following address",
          "This is the machine generated message from mail service",
          "This is the mail delivery agent at",
          "Unable to deliver message to the following address",
          "unable to deliver your message to the following addresses",
          "Unfortunately, your mail was not delivered to the following address:",
          "Your mail message to the following address",
          "Your message to the following addresses",
          "We're sorry.",
        ],
        "rhost"   => ['Giving up on ', 'Connected to ', 'remote host '],
      }.freeze
      CommandSet = {
        # qmail-remote.c:225|  if (smtpcode() != 220) quit("ZConnected to "," but greeting failed");
        Sisimai::Eb::CeCONN => [" but greeting failed."],
        # qmail-remote.c:231|  if (smtpcode() != 250) quit("ZConnected to "," but my name was rejected");
        Sisimai::Eb::CeEHLO => [" but my name was rejected."],
        # qmail-remote.c:238|  if (code >= 500) quit("DConnected to "," but sender was rejected");
        # reason = rejected
        Sisimai::Eb::CeMAIL => [" but sender was rejected."],
        # qmail-remote.c:249|  out("h"); outhost(); out(" does not like recipient.\n");
        # qmail-remote.c:253|  out("s"); outhost(); out(" does not like recipient.\n");
        # reason = userunknown
        Sisimai::Eb::CeRCPT => [" does not like recipient."],
        # qmail-remote.c:265|  if (code >= 500) quit("D"," failed on DATA command");
        # qmail-remote.c:266|  if (code >= 400) quit("Z"," failed on DATA command");
        # qmail-remote.c:271|  if (code >= 500) quit("D"," failed after I sent the message");
        # qmail-remote.c:272|  if (code >= 400) quit("Z"," failed after I sent the message");
        Sisimai::Eb::CeDATA => [" failed on DATA command", " failed after I sent the message"],
      }.freeze

      MessagesOf = {
        # notqmail 1.08 returns the following error message when the destination MX is NullMX
        Sisimai::Eb::Re00MX => ["Sorry, I couldn't find a mail exchanger or IP address"],
        Sisimai::Eb::ReUSER => ["no mailbox here by that name"],
      }.freeze

      # @abstract Decodes the bounce message from qmail
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        # Pre process email headers and the body part of the message which generated
        # by qmail, see https://cr.yp.to/qmail.html
        #   e.g.) Received: (qmail 12345 invoked for bounce); 29 Apr 2009 12:34:56 -0000
        #         Subject: failure notice
        proceedsto = false
        proceedsto = true if EmailTitle.any? { |a| mhead["subject"] == a }
        mhead["received"].each do |e|
          # Received: (qmail 2222 invoked for bounce);29 Apr 2017 23:34:45 +0900
          # Received: (qmail 2202 invoked from network); 29 Apr 2018 00:00:00 +0900
          proceedsto = true if Sisimai::String.aligned(e, ["(qmail", " invoked "])
        end
        return nil if proceedsto == false

        require "sisimai/smtp/command"
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]; v = nil
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if StartingOf["message"].any? { |a| e.include?(a) }
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0 || e.empty?

          # <kijitora@example.jp>:
          # 192.0.2.153 does not like recipient.
          # Remote host said: 550 5.1.1 <kijitora@example.jp>... User Unknown
          # Giving up on 192.0.2.153.
          v = dscontents[-1]

          if e.start_with?('<') && Sisimai::String.aligned(e, ['<', '@', '>:'])
            # <kijitora@example.jp>:
            if v["recipient"] != ""
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v["recipient"] = Sisimai::Address.s3s4(e[e.index("<"), e.size])
            recipients += 1

          elsif dscontents.size == recipients
            # Append error message
            v["diagnosis"] += "#{e} "
            v["alterrors"]  = e if e.start_with?(StartingOf["error"][0])

            next if v["rhost"] != ""
            StartingOf["rhost"].each do |r|
              # Find a remote host name
              p1 = e.index(r); next if p1.nil?
              cm = r.size
              p2 = e.index(" ", p1 + cm + 1) || p2 = e.rindex(".") 

              v["rhost"] = e[p1 + cm, p2 - p1 - cm]
              break
            end
          end
        end
        return nil if recipients == 0

        dscontents.each do |e|
          # Get the SMTP command name for the session
          CommandSet.each_key do |r|
            # Get the last SMTP command
            next if CommandSet[r].none? { |a| e["diagnosis"].include?(a) }
            e["command"] = r
            break
          end

          if e["diagnosis"].include?("Sorry, no SMTP connection got far enough")
            # Sorry, no SMTP connection got far enough; most progress was RCPT TO response; ...
            e["command"] = Sisimai::SMTP::Command.find(e["diagnosis"]) if e["command"].empty?
          end

          # Detect the reason of bounce
          if [Sisimai::Eb::CeHELO, Sisimai::Eb::CeEHLO].index(e["command"])
            # HELO | Connected to 192.0.2.135 but my name was rejected.
            e["reason"] = Sisimai::Eb::ReBLOC
          else
            # Try to match with each error message in the table
            # Check that the error message includes any of message patterns or not
            [e["alterrors"], e["diagnosis"]].each do |f|
              # Try to detect an error reason
              break if e["reason"] != ""
              next  if f.nil?
              MessagesOf.each_key do |r|
                # The key is a bounce reason name
                next if MessagesOf[r].none? { |a| f.include?(a) }
                e["reason"] = r
                break
              end
              break if e["reason"]
            end
          end

          e["command"] = Sisimai::SMTP::Command.find(e["diagnosis"]) if e["command"].empty?
        end

        return { "ds" => dscontents, "rfc822" => emailparts[1] }
      end
      def description; return 'qmail'; end
    end
  end
end

