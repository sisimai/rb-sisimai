module Sisimai::Lhost
  # Sisimai::Lhost::ApacheJames parses a bounce email which created by ApacheJames. Methods in the
  # module are called from only Sisimai::Message.
  module ApacheJames
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['Content-Type: message/rfc822'].freeze
      StartingOf = {
        # apache-james-2.3.2/src/java/org/apache/james/transport/mailets/
        #   AbstractNotify.java|124:  out.println("Error message below:");
        #   AbstractNotify.java|128:  out.println("Message details:");
        message: [''],
        error:   ['Error message below:'],
      }.freeze

      # Parse bounce messages from Apache James
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        match  = 0
        match += 1 if mhead['subject'] == '[BOUNCE]'
        match += 1 if mhead['message-id'].to_s.include?('.JavaMail.')
        match += 1 if mhead['received'].any? { |a| a.include?('JAMES SMTP Server') }
        return nil unless match > 0

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        issuedcode = ''     # (String) Alternative diagnostic message
        subjecttxt = nil    # (String) Alternative Subject text
        gotmessage = nil    # (Boolean) Flag for error message
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # Message details:
          #   Subject: Nyaaan
          #   Sent date: Thu Apr 29 01:20:50 JST 2015
          #   MAIL FROM: shironeko@example.jp
          #   RCPT TO: kijitora@example.org
          #   From: Neko <shironeko@example.jp>
          #   To: kijitora@example.org
          #   Size (in bytes): 1024
          #   Number of lines: 64
          v = dscontents[-1]

          if e.start_with?('  RCPT TO: ')
            #   RCPT TO: kijitora@example.org
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = e[12, e.size]
            recipients += 1

          elsif e.start_with?('  Sent date: ')
            #   Sent date: Thu Apr 29 01:20:50 JST 2015
            v['date'] = e[13, e.size]

          elsif e.start_with?('  Subject: ')
            #   Subject: Nyaaan
            subjecttxt = e[11, e.size]
          else
            next if gotmessage
            if v['diagnosis']
              # Get an error message text
              if e.start_with?('Message details:')
                # Message details:
                #   Subject: nyaan
                #   ...
                gotmessage = true
              else
                # Append error message text like the followng:
                #   Error message below:
                #   550 - Requested action not taken: no such user here
                v['diagnosis'] << ' ' << e
              end
            else
              # Error message below:
              # 550 - Requested action not taken: no such user here
              v['diagnosis'] = e if e == StartingOf[:error][0]
              unless gotmessage
                v['diagnosis'] ||= ''
                v['diagnosis'] << ' ' + e
              end
            end
          end
        end
        return nil unless recipients > 0

        # Set the value of subjecttxt as a Subject if there is no original message in the bounce mail.
        emailparts[1] << ('Subject: ' << subjecttxt << "\n") unless emailparts[1].index("\nSubject:")

        dscontents.each { |e| e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'] || issuedcode) }
        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Java Apache Mail Enterprise Server'; end
    end
  end
end

