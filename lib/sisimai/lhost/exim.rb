module Sisimai::Lhost
  # Sisimai::Lhost::Exim decodes a bounce email which created by Exim Internet Mailer https://www.exim.org/.
  # Methods in the module are called from only Sisimai::Message.
  module Exim
    class << self
      require 'sisimai/lhost'
      require 'sisimai/rfc1894'

      Indicators = Sisimai::Lhost.INDICATORS
      FieldTable = Sisimai::RFC1894.FIELDTABLE
      Boundaries = [
        # deliver.c:6423|          if (bounce_return_body) fprintf(f,
        # deliver.c:6424|"------ This is a copy of the message, including all the headers. ------\n");
        # deliver.c:6425|          else fprintf(f,
        # deliver.c:6426|"------ This is a copy of the message's headers. ------\n");
        "------ This is a copy of the message, including all the headers. ------",
        "Content-Type: message/rfc822",
        "Included is a copy of the message header:\n-----------------------------------------", # MXLogic
      ].freeze
      EmailTitle = [
        "Delivery Status Notification",
        "Mail delivery failed",
        "Mail failure",
        "Message frozen",
        "Warning: message ",
        "error(s) in forwarding or filtering",
      ].freeze
      StartingOf = {
        # Error text strings which defined in exim/src/deliver.c
        #
        # deliver.c:6292| fprintf(f,
        # deliver.c:6293|"This message was created automatically by mail delivery software.\n");
        # deliver.c:6294|        if (to_sender)
        # deliver.c:6295|          {
        # deliver.c:6296|          fprintf(f,
        # deliver.c:6297|"\nA message that you sent could not be delivered to one or more of its\n"
        # deliver.c:6298|"recipients. This is a permanent error. The following address(es) failed:\n");
        # deliver.c:6299|          }
        # deliver.c:6300|        else
        # deliver.c:6301|          {
        # deliver.c:6302|          fprintf(f,
        # deliver.c:6303|"\nA message sent by\n\n  <%s>\n\n"
        # deliver.c:6304|"could not be delivered to one or more of its recipients. The following\n"
        # deliver.c:6305|"address(es) failed:\n", sender_address);
        # deliver.c:6306|          }
        "alias"          => [" an undisclosed address"],
        "command"        => ["SMTP error from remote ", "LMTP error after "],
        "deliverystatus" => ["Content-Type: message/delivery-status"],
        "frozen"         => [" has been frozen", " was frozen on arrival"],
        "message"        => [
          "This message was created automatically by mail delivery software.",
          "A message that you sent was rejected by the local scannning code",
          "A message that you sent contained one or more recipient addresses ",
          "A message that you sent could not be delivered to all of its recipients",
          " has been frozen",
          " was frozen on arrival",
          " router encountered the following error(s):",
        ],
      }.freeze
      MessagesOf = {
        # find exim/ -type f -exec grep 'message = US' {} /dev/null \;
        # route.c:1158|  DEBUG(D_uid) debug_printf("getpwnam() returned NULL (user not found)\n");
        "userunknown" => ["user not found"],
        # parser.c:666| *errorptr = string_sprintf("%s (expected word or \"<\")", *errorptr);
        # parser.c:701| if(bracket_count++ > 5) FAILED(US"angle-brackets nested too deep");
        # parser.c:738| FAILED(US"domain missing in source-routed address");
        # parser.c:747| : string_sprintf("malformed address: %.32s may not follow %.*s",
        "syntaxerror" => [
          "angle-brackets nested too deep",
          'expected word or "<"',
          "domain missing in source-routed address",
          "malformed address:",
        ],
      }.freeze
      DelayedFor = [
        # deliver.c:7475| "No action is required on your part. Delivery attempts will continue for\n"
        # smtp.c:3508|    US"retry time not reached for any host after a long failure period" :
        # deliver.c:7459| print_address_error(addr, f, US"Delay reason: ");
        "No action is required on your part",
        "retry time not reached for any host after a long failure period",
        "Delay reason: ",
      ].freeze

      # @abstract Decodes the bounce message from Exim
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        # Message-Id: <E1P1YNN-0003AD-Ga@example.org>
        # X-Failed-Recipients: kijitora@example.ed.jp
        thirdparty = false
        proceedsto = 0
        messageidv = mhead["message-id"] || ""

        proceedsto += 1 if mhead["from"].include?("Mail Delivery System")
        while messageidv != "" do
          # Message-Id: <E1P1YNN-0003AD-Ga@example.org>
          break if messageidv.index("<") !=  0
          break if messageidv.index("-") !=  8
          break if messageidv.index('@') != 18
          proceedsto += 1; break
        end
        EmailTitle.each do |e|
          # Subject: Mail delivery failed: returning message to sender
          # Subject: Mail delivery failed
          # Subject: Message frozen
          next if mhead["subject"].include?(e) == false
          proceedsto += 1; break
        end

        while true
          # Exim clones of the third Parties
          # 1. McAfee Saas (Formerly MXLogic)
          if mhead.has_key?("x-mx-bounce")    then thirdparty = true; break; end
          if mhead.has_key?("x-mxl-hash")     then thirdparty = true; break; end
          if mhead.has_key?("x-mxl-notehash") then thirdparty = true; break; end
          if messageidv.include?("<mxl~")     then thirdparty = true; break; end
          break
        end
        return nil if proceedsto < 2 && thirdparty == false

        require "sisimai/reason"
        require "sisimai/address"
        require "sisimai/rfc2045"
        require "sisimai/smtp/command"
        require "sisimai/smtp/failure"

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]; v = nil
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        nextcursor = false
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        boundary00 = ""     # (String) Boundary string

        if mhead["content-type"]
          # Get the boundary string and set regular expression for matching with the boundary string.
          boundary00 = Sisimai::RFC2045.boundary(mhead["content-type"]) || ""
        end

        p1 = -1; p2 = -1;
        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            if StartingOf["message"].any? { |a| e.include?(a) }
              # Check the message defined in StartingOf["message"], ["frozen"]
              readcursor |= Indicators[:deliverystatus]
              next if StartingOf["frozen"].none? { |a| e.include?(a) }
            end
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0 || e.empty?

          # This message was created automatically by mail delivery software.
          #
          # A message that you sent could not be delivered to one or more of its
          # recipients. This is a permanent error. The following address(es) failed:
          #
          #  kijitora@example.jp
          #    SMTP error from remote mail server after RCPT TO:<kijitora@example.jp>:
          #    host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
          v = dscontents[-1]

          cv = ''
          ce = false
          while true
            # Check if the line matche the following patterns:
            break if e.start_with?("  ") == false       # The line should start with "  " (2 spaces)
            break if e.include?('@')     == false       # "@" should be included (email)
            break if e.include?(".")     == false       # "." should be included (domain part)
            break if e.include?("pipe to |")            # Exclude "pipe to /path/to/prog" line

            cx = e[2, 1]
            break if cx == " "                          # The 3rd character is " "
            break if thirdparty == false && cx == "<"   # MXLogic returns "  <neko@example.jp>:..."
            ce = true
            break
          end

          if ce == true || e.include?(StartingOf["alias"][0])
            # The line is including an email address
            if v["recipient"] != ""
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end

            if e.include?(StartingOf["alias"][0])
              # The line does not include an email address
              # deliver.c:4549|  printed = US"an undisclosed address";
              #   an undisclosed address
              #     (generated from kijitora@example.jp)
              cv = e[2, e.size]
            else
              #   kijitora@example.jp
              #   sabineko@example.jp: forced freeze
              #   mikeneko@example.jp <nekochan@example.org>: ...
              p1 = e.index("<") || -1
              p2 = e.index(">:") || -1

              if p1 > 1 && p2 > 1
                # There are an email address and an error message in the line
                # parser.c:743| while (bracket_count-- > 0) if (*s++ != '>')
                # parser.c:744|   {
                # parser.c:745|   *errorptr = s[-1] == 0
                # parser.c:746|     ? US"'>' missing at end of address"
                # parser.c:747|     : string_sprintf("malformed address: %.32s may not follow %.*s",
                # parser.c:748|     s-1, (int)(s - US mailbox - 1), mailbox);
                # parser.c:749|   goto PARSE_FAILED;
                # parser.c:750|   }
                cv = Sisimai::Address.s3s4(e[p1, p2 - p1 - 1])
                v["diagnosis"] = Sisimai::String.sweep(e[p2 + 1, e.size])
              else
                # There is an email address only in the line
                #   kijitora@example.jp
                cv = Sisimai::Address.s3s4(e[2, e.size])
              end
            end
            v["recipient"] = cv
            recipients += 1

          elsif e.include?(" (generated from ") || e.include?(" generated by ")
            #     (generated from kijitora@example.jp)
            #  pipe to |/bin/echo "Some pipe output"
            #    generated by userx@myhost.test.ex
            e.split(" ").each do |f|
              # Find the alias address
              next if f.include?('@') == false
              v["alias"] = Sisimai::Address.s3s4(f)
            end
          else
            if StartingOf["frozen"].any? { |a| e.include?(a) }
              # Message *** has been frozen by the system filter.
              # Message *** was frozen on arrival by ACL.
              v["alterrors"] ||= ""
              v["alterrors"]  += "#{e} "
            elsif boundary00 != ""
              # --NNNNNNNNNN-eximdsn-MMMMMMMMMM
              # Content-type: message/delivery-status
              # ...
              if Sisimai::RFC1894.match(e) > 0
                # "e" matched with any field defined in RFC3464
                next unless o = Sisimai::RFC1894.field(e)

                if o[3] == "addr"
                  # Final-Recipient: rfc822; kijitora@example.jp
                  # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                  next if o[0] != "final-recipient"
                  if v["spec"].empty?
                    v["spec"] = o[2].include?('@') ? "SMTP" : "X-UNIX"
                  end

                elsif o[3] == "code"
                  # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                  v["spec"] = o[1].upcase
                  v["diagnosis"] = o[2]

                else
                  # Other DSN fields defined in RFC3464
                  next if FieldTable[o[0]].nil?
                  v[FieldTable[o[0]]] = o[2]
                end
              else
                # Error message ?
                next if nextcursor

                # Content-type: message/delivery-status
                nextcursor = true if e.start_with?(StartingOf["deliverystatus"][0])
                v["alterrors"] ||= ''
                v["alterrors"]  += "#{e} " if e.start_with?(" ")
              end
            else
              # There is no boundary string in $boundary00
              if dscontents.size == recipients
                # Error message
                v["diagnosis"] += "#{e} "
              else
                # Error message when email address above does not include '@' and domain part
                # pipe to |/path/to/prog ...
                #   generated by kijitora@example.com
                next if e.start_with?("  ") == false
                v["diagnosis"] += "#{e} "
              end
            end
          end
        end

        if recipients > 0
          # Check "an undisclosed address", "unroutable address"
          dscontents.each do |q|
            # Replace the recipient address with the value of "alias"
            next if q["alias"].empty?
            if q["recipient"].empty? || q["recipient"].include?('@') == false
              # The value of "recipient" is empty or does not include "@"
              q["recipient"] = q["alias"]
            end
          end
        else
          # Fallback for getting recipient addresses
          if mhead["x-failed-recipients"]
            # X-Failed-Recipients: kijitora@example.jp
            rcptinhead = mhead["x-failed-recipients"].split(",")
            rcptinhead.each do |e|
              # Remove space characters
              e.lstrip!
              e.rstrip!
            end
            recipients = rcptinhead.size

            while e = rcptinhead.shift do
              # Insert each recipient address into dscontents
              dscontents[-1]["recipient"] = e
              next if dscontents.size == recipients
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
            end
          end
        end
        return nil if recipients == 0

        # Get the name of the local MTA
        # Received: from marutamachi.example.org (c192128.example.net [192.0.2.128])
        receivedby = mhead["received"] || []
        recvdtoken = Sisimai::RFC5322.received(receivedby[-1])

        dscontents.each do |e|
          # Check the error message, the rhost, the lhost, and the smtp command.
          e["alterrors"] = "" if e["alterrors"].nil?
          if e["diagnosis"].empty? && boundary00.size > 0
            # Empty Diagnostic-Code: or error message
            # --NNNNNNNNNN-eximdsn-MMMMMMMMMM
            # Content-type: message/delivery-status
            #
            # Reporting-MTA: dns; the.local.host.name
            #
            # Action: failed
            # Final-Recipient: rfc822;/a/b/c
            # Status: 5.0.0
            #
            # Action: failed
            # Final-Recipient: rfc822;|/p/q/r
            # Status: 5.0.0
            e["diagnosis"] = dscontents[0]["diagnosis"]
            e["spec"]      = dscontents[0]["spec"]      if e["spec"].empty?
            e["alterrors"] = dscontents[0]["alterrors"] if dscontents[0]["alterrors"] != ""
          end

          if e["alterrors"]
            # Copy alternative error message
            e["diagnosis"] = e["alterrors"] if e["diagnosis"].empty?

            if e["diagnosis"].start_with?("-") || e["diagnosis"].end_with?("__")
              # Override the value of diagnostic code message
              e["diagnosis"] = e["alterrors"]

            elsif e["diagnosis"].size < e["alterrors"].size
              # Override the value of diagnostic code message with the value of alterrors because
              # the latter includes the former.
              e["alterrors"].squeeze!(" ")
              e["diagnosis"] = e["alterrors"] if e["alterrors"].downcase.include?(e["diagnosis"].downcase)
            end
            e.delete("alterrors")
          end
          e["diagnosis"] = Sisimai::String.sweep(e["diagnosis"]) || ""; p1 = e["diagnosis"].index("__") || -1
          e["diagnosis"] = e["diagnosis"][0, p1] if p1 > 1

          if e["rhost"].empty?
            # Get the remote host name
            # host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
            p1 = e["diagnosis"].index("host ")     || -1
            p2 = e["diagnosis"].index(" ", p1 + 5) || -1
            e["rhost"] = e["diagnosis"][p1 + 5, p2 - p1 - 5] if p1 > -1
            e["rhost"] = recvdtoken[1] if e["rhost"].empty?
          end
          e["lhost"] = recvdtoken[0] if e["lhost"].empty?

          if e["command"].empty?
            # Get the SMTP command name for the session
            StartingOf["command"].each do |r|
              # Verify each regular expression of SMTP commands
              next if e["diagnosis"].include?(r) == false
              e["command"] = Sisimai::SMTP::Command.find(e["diagnosis"]); next if e["command"].empty?
              break
            end

            # Detect the reason of bounce
            if %w[HELO EHLO].index(e["command"])
              # HELO | Connected to 192.0.2.135 but my name was rejected.
              e["reason"] = "blocked"

            elsif e["command"] == "MAIL"
              # MAIL | Connected to 192.0.2.135 but sender was rejected.
              e["reason"] = "onhold"

            else
              # Try to match the error message with each message pattern 
              MessagesOf.each_key do |r|
                # Check each message pattern
                next if MessagesOf[r].none? { |a| e["diagnosis"].include?(a) }
                e["reason"] = r
                break
              end

              if e["reason"].empty?
                e["reason"] = "expired" if DelayedFor.any? { |a| e["diagnosis"].include?(a) }
              end
            end
          end

          # Prefer the value of smtp reply code in Diagnostic-Code:
          #   Action: failed
          #   Final-Recipient: rfc822;userx@test.ex
          #   Status: 5.0.0
          #   Remote-MTA: dns; 127.0.0.1
          #   Diagnostic-Code: smtp; 450 TEMPERROR: retry timeout exceeded
          #
          # The value of "Status:" indicates permanent error but the value of SMTP reply code in
          # Diagnostic-Code: field is "TEMPERROR"!!!!
          cr = Sisimai::SMTP::Reply.find(e["diagnosis"], e["status"])
          cs = Sisimai::SMTP::Status.find(e["diagnosis"], cr)
          re = e["reason"]
          cv = ""

          if Sisimai::SMTP::Failure.is_temporary(cr) || re == "expired"
            # Set the pseudo status code as a temporary error
            cv = Sisimai::SMTP::Status.code(re, true) if Sisimai::Reason.is_explicit(re)
          end
          e["replycode"] = cr if e["replycode"].empty?
          e["status"]    = Sisimai::SMTP::Status.prefer(cv, cs, cr) if e["status"].empty?
        end

        return { "ds" => dscontents, "rfc822" => emailparts[1] }
      end
      def description; return "Exim"; end
    end
  end
end

