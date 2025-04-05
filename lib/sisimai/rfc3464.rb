module Sisimai
  # Sisimai::RFC3464 - bounce mail decoder class for Fallback.
  module RFC3464
    class << self
      require 'sisimai/lhost'
      require 'sisimai/string'
      require 'sisimai/address'
      require 'sisimai/rfc1123'
      require 'sisimai/rfc1894'
      require 'sisimai/rfc2045'
      require 'sisimai/rfc5322'
      require 'sisimai/rfc3464/thirdparty'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = [
        # When the new value added, the part of the value should be listed in delimiters variable
        # defined at Sisimai::RFC2045.makeFlat() method
        "Content-Type: message/rfc822",
        "Content-Type: text/rfc822-headers",
        "Content-Type: message/partial",
        "Content-Disposition: inline", # See lhost-amavis-*.eml, lhost-facebook-*.eml
      ].freeze
      StartingOf = { message: ["Content-Type: message/delivery-status"] }.freeze
      FieldTable = Sisimai::RFC1894.FIELDTABLE

      # Decode a bounce mail which have fields defined in RFC3464
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        # There is no "Content-Type: message/rfc822" line in the message body
        if Boundaries.any? { |a| mbody.include?(a) } == false
          # Insert "Content-Type: message/rfc822" before "Return-Path:" of the original message
          p0 = mbody.index("\n\nReturn-Path:")
          mbody = sprintf("%s%s%s", mbody[0, p0], Boundaries[0], mbody[p0 + 1, mbody.size]) if p0
        end

        permessage = {}
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]; v = nil
        alternates = Sisimai::Lhost.DELIVERYSTATUS
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        readslices = [""]
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        beforemesg = ""     # (String) String before StartingOf[:message]
        goestonext = false  # (Bool) Flag: do not append the line into beforemesg
        isboundary = [Sisimai::RFC2045.boundary(mhead["content-type"], 0)]; isboundary[0] ||= ""

        while emailparts[0].index('@').nil? do
          # There is no email address in the first element of emailparts
          # There is a bounce message inside of message/rfc822 part at lhost-x5-*
          p0 = -1 # The index of the boundary string found first
          p1 =  0 # Offset position of the message body after the boundary string
          ct = "" # Boundary string found first such as "Content-Type: message/rfc822"

          Boundaries.each do |e|
            # Look for a boundary string from the message body
            p0 = mbody.index(e + "\n"); next if p0.nil?
            p1 = p0 + e.size + 2
            ct = e; break
          end
          break if p0.nil?

          cx = mbody[p1, mbody.size]
          p2 = cx.index("\n\n")
          cv = cx[p2 + 2, mbody.size]
          emailparts = Sisimai::RFC5322.part(cv, [ct], 0)
          break
        end

        if emailparts[0].index(StartingOf[:message][0]) == nil
          # There is no "Content-Type: message/delivery-status" line in the message body
          # Insert "Content-Type: message/delivery-status" before "Reporting-MTA:" field
          cv = "\nReporting-MTA:"
          e0 = emailparts[0]
          p0 = e0.index(cv)
          emailparts[0] = sprintf("%s\n\n%s%s", e0[0, p0], StartingOf[:message][0], e0[p0, e0.size]) if p0
        end

        %w[Final-Recipient Original-Recipient].each do |e|
          # Fix the malformed field "Final-Recipient: <kijitora@example.jp>"
          cv = "\n" + e + ": "
          cx = cv + "<"
          p0 = emailparts[0].index(cx); next if p0.nil?

          emailparts[0] = emailparts[0].sub(": <", ": rfc822; ")
          p1 = emailparts[0].index(">\n", p0 + 2); emailparts[0][p1, 1] = ""
        end

        bodyslices = emailparts[0].scrub('?').split("\n")
        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          readslices << e # Save the current line for the next loop

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(StartingOf[:message][0])

            while true do
              # Append each string before startingof["message"][0] except the following patterns
              # for the later reference
              break if e.empty?   # Blank line
              break if goestonext # Skip if the part is text/html, image/icon, in multipart/*

              # This line is a boundary kept in "multiparts" as a string, when the end of the boundary
              # appeared, the condition above also returns true.
              if isboundary.any? { |a| e == a } then goestonext = false; break; end
              if e.start_with?("Content-Type:")
                # Content-Type: field in multipart/*
                if e.include?("multipart/")
                  # Content-Type: multipart/alternative; boundary=aa00220022222222ffeebb
                  # Pick the boundary string and store it into "isboucdary"
                  isboundary << Sisimai::RFC2045.boundary(e, 0)
                elsif e.include?("text/plain")
                  # Content-Type: "text/plain"
                  goestonext = false
                else
                  # Other types: for example, text/html, image/jpg, and so on
                  goestonext = true
                end
                break
              end

              break if e.start_with?("Content-")        # Content-Disposition, ...
              break if e.start_with?("This is a MIME")  # This is a MIME-formatted message.
              break if e.start_with?("This is a multi") # This is a multipart message in MIME format
              break if e.start_with?("This is an auto") # This is an automatically generated ...
              break if e.start_with?("This multi-part") # This multi-part MIME message contains...
              break if e.start_with?("###")             # A frame like #####
              break if e.start_with?("***")             # A frame like *****
              break if e.start_with?("--")              # Boundary string
              break if e.include?("--- The follow")     # ----- The following addresses had delivery problems -----
              break if e.include?("--- Transcript")     # ----- Transcript of session follows -----
              beforemesg << e + " "; break
            end
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0 || e.empty?

          f = Sisimai::RFC1894.match(e)
          if f > 0
            # "e" matched with any field defined in RFC3464
            next unless o = Sisimai::RFC1894.field(e)
            v = dscontents[-1]

            if o[3] == "addr"
              # Final-Recipient: rfc822; kijitora@example.jp
              # X-Actual-Recipient: rfc822; kijitora@example.co.jp
              if o[0] == "final-recipient"
                # Final-Recipient: rfc822; kijitora@example.jp
                # Final-Recipient: x400; /PN=...
                cv = Sisimai::Address.s3s4(o[2]); next unless Sisimai::Address.is_emailaddress(cv)
                cw = dscontents.size;             next if cw > 0 && cv == dscontents[cw - 1]["recipient"]

                if v["recipient"] != ""
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Lhost.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v["recipient"] = cv
                recipients += 1
              else
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                v["alias"] = o[2]
              end
            elsif o[3] == "code"
              # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
              v["spec"]      = o[1]
              v["diagnosis"] = o[2]
            else
              # Other DSN fields defined in RFC3464
              if o[4].size > 0
                # There are other error messages as a comment such as the following:
                # Status: 5.0.0 (permanent failure)
                # Status: 4.0.0 (cat.example.net: host name lookup failure)
                v["diagnosis"] << " " + o[4] + " "
              end
              next unless FieldTable[o[0]]
              next if o[3] == "host" && Sisimai::RFC1123.is_internethost(o[2]) == false
              v[FieldTable[o[0]]] = o[2]

              next unless f == 1
              permessage[FieldTable[o[0]]] = o[2]
            end
          else
            # Check that the line is a continued line of the value of Diagnostic-Code: field or not
            if e.start_with?("X-") && e.include?(": ")
              # This line is a MTA-Specific fields begins with "X-"
              next unless Sisimai::RFC3464::ThirdParty.is3rdparty(e)
              cv = Sisimai::RFC3464::ThirdParty.xfield(e)

              if cv.size > 0 && FieldTable[cv[0].downcase] == nil
                # Check the first element is a field defined in RFC1894 or not
                p1 = cv[4].index(":")
                v["reason"] = cv[4][p1 + 1, cv[4].size] if cv[4].start_with?("reason:")
              else
                # Set the value picked from "X-*" field to $dscontents when the current value is empty
                z = FieldTable[cv[0].downcase]; next unless z
                v[z] ||=  cv[2]
              end
            else
              # The line may be a continued line of the value of the Diagnostic-Code: field
              if readslices[-2].start_with?("Diagnostic-Code:") == false
                # In the case of multiple "message/delivery-status" line
                next if e.start_with?("Content-") # Content-Disposition:, ...
                next if e.start_with?("--")       # Boundary string
                beforemesg << e + " "; next
              end

              # Diagnostic-Code: SMTP; 550-5.7.26 The MAIL FROM domain [email.example.jp]
              #    has an SPF record with a hard fail
              next unless e.start_with?(" ")
              v["diagnosis"] << " " + Sisimai::String.sweep(e)
            end
          end
        end

        while recipients == 0 do
          # There is no valid recipient address, Try to use the alias addaress as a final recipient
          break if dscontents[0]["alias"].nil? || dscontents[0]["alias"].empty?
          break if Sisimai::Address.is_emailaddress(dscontents[0]["alias"]) == false
          dscontents[0]["recipient"] = dscontents[0]["alias"]
          recipients += 1
        end
        return nil if recipients == 0

        require "sisimai/smtp/reply"
        require "sisimai/smtp/status"
        require "sisimai/smtp/command"

        if beforemesg != ""
          # Pick some values of $dscontents from the string before StartingOf[:message]
          beforemesg = Sisimai::String.sweep(beforemesg)
          alternates["command"]   = Sisimai::SMTP::Command.find(beforemesg)
          alternates["replycode"] = Sisimai::SMTP::Reply.find(beforemesg, dscontents[0]["status"])
          alternates["status"]    = Sisimai::SMTP::Status.find(beforemesg, alternates["replycode"])
        end
        issuedcode = beforemesg.downcase

        dscontents.each do |e|
          # Set default values stored in "permessage" if each value in "dscontents" is empty.
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }
          e["diagnosis"] = Sisimai::String.sweep(e["diagnosis"])
          lowercased = e["diagnosis"].downcase

          if recipients == 1
            # Do not mix the error message of each recipient with "beforemesg" when there is
            # multiple recipient addresses in the bounce message
            if issuedcode.include?(lowercased)
              # beforemesg contains the entire strings of e["diagnosis"]
              e["diagnosis"] = beforemesg
            else
              # The value of e["diagnosis"] is not contained in $beforemesg
              # There may be an important error message in $beforemesg
              e["diagnosis"] = Sisimai::String.sweep(sprintf("%s %s", beforemesg, e["diagnosis"]))
            end
          end
          e["command"]   = Sisimai::SMTP::Command.find(e["diagnosis"])
          e["command"]   = alternates["command"]   if e["command"].empty? 
          e["replycode"] = Sisimai::SMTP::Reply.find(e["diagnosis"], e["status"])
          e["replycode"] = alternates["replycode"] if e["replycode"].empty? 
          e["status"]    = Sisimai::SMTP::Status.find(e["diagnosis"], e["replycode"]) if e["status"].empty?
          e["status"]    = alternates["status"] if e["status"].empty?
        end

        if emailparts[1].nil? || emailparts[1].empty?
          # Set the recipient address as To: header in the original message part
          emailparts[1] = sprintf("To: <%s>\n", dscontents[0]["recipient"])
        end
        return { "ds" => dscontents, "rfc822" => emailparts[1] }
      end

      def description; 'RFC3464'; end
    end
  end
end

