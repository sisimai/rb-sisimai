module Sisimai::Lhost
  # Sisimai::Lhost::GoogleWorkspace decodes a bounce email which created by Google Workspace.
  # Methods in the module are called only from Sisimai::Message.
  module GoogleWorkspace
    class << self
      require 'sisimai/lhost'
      require 'sisimai/string'
      require 'sisimai/address'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ["Content-Type: message/rfc822", "Content-Type: text/rfc822-headers"].freeze
      StartingOf = {
        message: ["** "],
        error:   ["The response was:", "The response from the remote server was:"],
      }.freeze
      MessagesOf = {
        "userunknown"  => ["because the address couldn't be found. Check for typos or unnecessary spaces and try again."],
        "notaccept"    => ["Null MX"],
        "networkerror" => [" had no relevant answers.", " responded with code NXDOMAIN"],
      }.freeze

      # @abstract Decodes the bounce message from Google Workspace
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      # @see https://workspace.google.com/.
      def inquire(mhead, mbody)
        return nil if mbody.include?("\nDiagnostic-Code:") || mbody.include?("\nFinal-Recipient:")
        return nil if mhead["from"].include?('<mailer-daemon@googlemail.com>') == false
        return nil if mhead["subject"].include?("Delivery Status Notification") == false

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        entiremesg = ""
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            if e.start_with?(StartingOf[:message][0])
              # ** Message not delivered **
              readcursor |= Indicators[:deliverystatus]
              entiremesg += "#{e }"
            end
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0 || e.empty?

          # ** Message not delivered **
          # You're sending this from a different address or alias using the 'Send mail as' feature.
          # The settings for your 'Send mail as' account are misconfigured or out of date. Check those settings and try resending.
          # Learn more here: https://support.google.com/mail/?p=CustomFromDenied
          # The response was:
          # Unspecified Error (SENT_SECOND_EHLO): Smtp server does not advertise AUTH capability
          next if e.start_with?("Content-Type: ")
          entiremesg += "#{e }"
        end

        while recipients == 0 do
          # Pick the recipient address from the value of To: header of the original message after
          # Content-Type: message/rfc822 field
          p0 = emailparts[1].index("\nTo:"); break if p0.nil?
          p1 = emailparts[1].index("\n", p0 + 2)
          cv = Sisimai::Address.s3s4(emailparts[1][p0 + 4, p1 - p0])
          dscontents[0]["recipient"] = cv
          recipients += 1
        end
        return nil if recipients == 0

        dscontents[0]["diagnosis"] = entiremesg
        dscontents.each do |e|
          # Tidy up the error message in e["diagnosis"], Try to detect the bounce reason.
          e["diagnosis"] = Sisimai::String.sweep(e["diagnosis"])
          MessagesOf.each_key do |r|
            # Guess an reason of the bounce
            next if MessagesOf[r].none? { |a| e["diagnosis"].include?(a) }
            e["reason"] = r
            break
          end
        end

        return { "ds" => dscontents, "rfc822" => emailparts[1] }
      end
      def description; return "Google Workspace: https://workspace.google.com/"; end
    end
  end
end

