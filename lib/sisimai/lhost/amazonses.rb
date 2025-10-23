module Sisimai::Lhost
  # Sisimai::Lhost::AmazonSES decodes a bounce email which created by Amazon Simple Email Service
  # https://aws.amazon.com/ses/. Methods in the module are called from only Sisimai::Message.
  module AmazonSES
    # ---------------------------------------------------------------------------------------------
    # "notificationType": "Bounce"
    # https://docs.aws.amazon.com/ses/latest/dg/notification-contents.html#bounce-object
    #
    # Bounce types
    #   The bounce object contains a bounce type of Undetermined, Permanent, or Transient. The
    #   Permanent and Transient bounce types can also contain one of several bounce subtypes.
    #
    #   When you receive a bounce notification with a bounce type of Transient, you might be
    #   able to send email to that recipient in the future if the issue that caused the message
    #   to bounce is resolved.
    #
    #   When you receive a bounce notification with a bounce type of Permanent, it's unlikely
    #   that you'll be able to send email to that recipient in the future. For this reason, you
    #   should immediately remove the recipient whose address produced the bounce from your
    #   mailing lists.
    #
    # "bounceType"/"bounceSubType" "Desription"
    # Undetermined/Undetermined -- The bounce message didn't contain enough information for
    #                              Amazon SES to determine the reason for the bounce.
    #
    # Permanent/General ---------- When you receive this type of bounce notification, you should
    #                              immediately remove the recipient's email address from your
    #                              mailing list.
    # Permanent/NoEmail ---------- It was not possible to retrieve the recipient email address
    #                              from the bounce message.
    # Permanent/Suppressed ------- The recipient's email address is on the Amazon SES suppression
    #                              list because it has a recent history of producing hard bounces.
    # Permanent/OnAccountSuppressionList
    #                              Amazon SES has suppressed sending to this address because it
    #                              is on the account-level suppression list.
    # 
    # Transient/General ---------- You might be able to send a message to the same recipient
    #                              in the future if the issue that caused the message to bounce
    #                              is resolved.
    # Transient/MailboxFull ------ the recipient's inbox was full.
    # Transient/MessageTooLarge -- message you sent was too large
    # Transient/ContentRejected -- message you sent contains content that the provider doesn't allow
    # Transient/AttachmentRejected the message contained an unacceptable attachment
    class << self
      require 'sisimai/lhost'

      ReasonPair = {
        "Supressed"                => "suppressed",
        "OnAccountSuppressionList" => "suppressed",
        "General"                  => "onhold",
        "MailboxFull"              => "mailboxfull",
        "MessageTooLarge"          => "mesgtoobig",
        "ContentRejected"          => "contenterror",
        "AttachmentRejected"       => "securityerror",
      }.freeze

      # @abstract Decodes the bounce message from Amazon SES
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        return nil if mbody.include?("{") == false
        return nil if mhead.has_key?("x-amz-sns-message-id") == false
        return nil if mhead["x-amz-sns-message-id"].empty?

        proceedsto = false
        sespayload = mbody
        while true
          # Remote the following string begins with "--"
          # --
          # If you wish to stop receiving notifications from this topic, please click or visit the link below to unsubscribe:
          # https://sns.us-west-2.amazonaws.com/unsubscribe.html?SubscriptionArn=arn:aws:sns:us-west-2:1...
          p1 = mbody.index("\n\n--\n")
          sespayload = mbody[0, p1] if p1
          sespayload = sespayload.gsub("!\n ", "")
          p2 = sespayload.index('"Message"')

          if p2
            # The JSON included in the email is a format like the following:
            # {
            #  "Type" : "Notification",
            #  "MessageId" : "02f86d9b-eecf-573d-b47d-3d1850750c30",
            #  "TopicArn" : "arn:aws:sns:us-west-2:123456789012:SES-EJ-B",
            #  "Message" : "{\"notificationType\"...
            sespayload = sespayload.gsub("\\", "")
            p3 = sespayload.index("{", p2 + 9)
            p4 = sespayload.index("\n", p2 + 9)
            sespayload = sespayload[p3, p4 - p3]
            sespayload = sespayload.delete_suffix(',').delete_suffix('"')
          end

          break if sespayload.include?("notificationType") == false
          break if sespayload.start_with?("{")             == false
          break if sespayload.end_with?("}")               == false
          proceedsto = true; break
        end
        return nil if proceedsto == false

        jsonobject = nil
        begin
          if RUBY_PLATFORM.start_with?("java")
            # java-based ruby environment like JRuby.
            require "jrjackson"
            jsonobject = JrJackson::Json.load(sespayload)
          else
            # Matz' Ruby Implementation
            require "oj"
            jsonobject = Oj.load(sespayload)
          end
        rescue StandardError => ce
          # Something wrong in decoding JSON
          warn " ***warning: Failed to decode JSON: #{ce.to_s}"
          return nil
        end
        return nil if jsonobject.has_key?("notificationType") == false

        require "sisimai/string"
        require "sisimai/rfc1123"
        require "sisimai/smtp/reply"
        require "sisimai/smtp/status"
        require "sisimai/smtp/command"
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]; v = dscontents[-1]
        recipients = 0  # (Integer) The number of 'Final-Recipient' header
        whatnotify = jsonobject["notificationType"][0, 1] || ""

        if whatnotify == "B"
          # "notificationType":"Bounce"
          p = jsonobject["bounce"]
          r = p["bounceType"] == "Permanent" ? "5" : "4"

          p["bouncedRecipients"].each do |e|
            # {"emailAddress":"neko@example.jp", "action":"failed", "status":"5.1.1", "diagnosticCode": "..."}
            if v["recipient"] != ""
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v["recipient"] = e["emailAddress"]
            v["diagnosis"] = Sisimai::String.sweep(e["diagnosticCode"])
            v["command"]   = Sisimai::SMTP::Command.find(v["diagnosis"])
            v["action"]    = e["action"]
            v["status"]    = Sisimai::SMTP::Status.find(v["diagnosis"], r)
            v["replycode"] = Sisimai::SMTP::Reply.find(v["diagnosis"], v["status"])
            v["date"]      = p["timestamp"]
            v["lhost"]     = Sisimai::RFC1123.find(p["reportingMTA"])
            recipients += 1
          end

          ReasonPair.each_key do |f|
            #  Try to find the bounce reason by "bounceSubType"
            next unless ReasonPair[f] == p["bounceSubType"]
            v["reason"] = f; break
          end

        elsif whatnotify == "C"
          # "notificationType":"Complaint"
          p = jsonobject["complaint"]
          p["complainedRecipients"].each do |e|
            # {"emailAddress":"neko@example.jp"}
            if v["recipient"] != ""
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v["recipient"]    = e["emailAddress"]
            v["reason"]       = "feedback"
            v["feedbacktype"] = p["complaintFeedbackType"]
            v["date"]         = p["timestamp"]
            v["diagnosis"]    = sprintf('"feedbackid":"%s", "useragent":"%s"}', p["feedbackId"], p["userAgent"])
            recipients += 1
          end

        elsif whatnotify == "D"
          # "notificationType":"Delivery"
          p = jsonobject["delivery"]
          p["recipients"].each do |e|
            # {"recipients":["neko@example.jp"]}
            if v["recipient"] != ""
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v["recipient"] = e
            v["reason"]    = "delivered"
            v["action"]    = "delivered"
            v["date"]      = p["timestamp"]
            v["lhost"]     = Sisimai::RFC1123.find(p["reportingMTA"])
            v["diagnosis"] = Sisimai::String.sweep(p["smtpResponse"])
            v["command"]   = Sisimai::SMTP::Command.find(v["diagnosis"])
            v["status"]    = Sisimai::SMTP::Status.find(v["diagnosis"], "2")
            v["replycode"] = Sisimai::SMTP::Reply.find(v["diagnosis"], "2")
            recipients += 1
          end

        else
          # Unknown "notificationType" value
          warn sprintf(" ***warning: There is no notificationType field or unknown type of notificationType field")
          return nil
        end
        return nil if recipients == 0

        # Date::Time.strptime() cannot parse "2016-11-25T01:49:01.000Z" format
        dscontents.each { |e| e["date"] = e["date"].sub("T", " ").sub(/[.]\d{3}Z/, "") }

        cv = ""
        jsonobject["mail"]["headers"].each do |e|
          cv += sprintf("%s: %s\n", e["name"], e["value"])
        end
        %w[date subject].each do |e|
          next if jsonobject["mail"]["commonHeaders"].has_key?(e) == false
          cv += sprintf("%s: %s\n", e.capitalize, jsonobject["mail"]["commonHeaders"][e])
        end
        return {"ds" => dscontents, "rfc822" => cv}
      end
      def description; return 'Amazon SES(Sending): https://aws.amazon.com/ses/'; end
    end
  end
end

