module Sisimai::Lhost
  # Sisimai::Lhost::X2 decodes a bounce email which created by Unknown MTA #2. Methods in the module
  # are called from only Sisimai::Message.
  module X2
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['--- Original message follows.'].freeze
      StartingOf = {
        message: [
          "Unable to deliver message to the following address",
          "This Delivery Status Notification is sent from MTA",
        ]}.freeze

      # @abstract Decodes the bounce message from Unknown MTA #2
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        match   = false
        match ||= true if mhead['from'].include?('MAILER-DAEMON@')
        match ||= true if mhead['subject'].start_with?('Delivery failure')
        match ||= true if mhead['subject'].start_with?('failure delivery')
        match ||= true if mhead['subject'].start_with?('failed delivery')
        return nil if match == false

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
            readcursor |= Indicators[:deliverystatus] if StartingOf[:message].any? { |a| e.start_with?(a) }
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0 || e.empty?

          # Message from example.com.
          # Unable to deliver message to the following address(es).
          #
          # <kijitora@example.com>:
          # This user doesn't have a example.com account (kijitora@example.com) [0]
          # 
          # --- OR ---
          # 
          # This Delivery Status Notification is sent from MTA...
          # 
          # Your delivery to the following address has been failed.
          # Please refer to the below for details.
          # ------------------------------------------------------
          # 
          # Delivery failed: kijitora@example.co.jp
          # 192.0.2.25 does not like recipient.
          # Remote host said[Response Message]: 550 5.1.1 <kijitora@example.co.jp>:
          #   Recipient address rejected: User unknown in local recipient table
          # Giving up on 192.0.2.25.
          # STEP: RCPT TO
          v = dscontents[-1]

          if e.start_with?('<')                 && Sisimai::String.aligned(e, ['<', '@', '>:']) ||
             e.start_with?('Delivery failed: ') && Sisimai::String.aligned(e, ['failed: ', '@'])
            # <kijitora@example.com>:
            # Delivery failed: kijitora@example.co.jp
            if v["recipient"] != ""
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = e[1, e.size - 3] if e.start_with?('<')
            v['recipient'] = e[e.index(': ') + 2, e.size - 1] if v['recipient'].empty?
            recipients += 1

          elsif e.start_with?('STEP: ')
            # STEP: RCPT TO
            # STEP: DATA SEND
            v['command'] = Sisimai::SMTP::Command.find(e)

          elsif e.start_with?('-----') == false
            # This user doesn't have a example.com account (kijitora@example.com) [0]
            v['diagnosis'] += " #{e}"
          end
        end
        return nil if recipients == 0
        return {"ds" => dscontents, "rfc822" => emailparts[1]}
      end
      def description; return 'Unknown MTA #2'; end
    end
  end
end

