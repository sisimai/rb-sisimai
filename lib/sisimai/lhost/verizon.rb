module Sisimai::Lhost
  # Sisimai::Lhost::Verizon decodes a bounce email which created by Verizon https://www.verizon.com/.
  # Methods in the module are called from only Sisimai::Message.
  module Verizon
    class << self
      require 'sisimai/lhost'
      Indicators = Sisimai::Lhost.INDICATORS

      # @abstract Decodes the bounce message from Verizon
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        match = -1
        while true
          # Check the value of "From" header
          # :'subject' => %r/Undeliverable Message/,
          break unless mhead['received'].any? { |a| a.include?('.vtext.com (') }
          match = 1 if mhead['from'] == 'post_master@vtext.com'
          match = 0 if Sisimai::String.aligned(mhead['from'], ['sysadmin@', '.vzwpix.com'])
          break
        end
        return nil if match < 0

        boundaries = []
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = []
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        senderaddr = ''     # (String) Sender address in the message body
        subjecttxt = ''     # (String) Subject of the original message
        markingsof = {}     # (Hash) Delimiter patterns
        startingof = {}     # (Hash) Delimiter strings
        messagesof = {}     # (Hash) Error message patterns
        v = nil

        if match == 1
          # vtext.com
          markingsof = { message: ['Error: '] }
          messagesof = {
            # The attempted recipient address does not exist.
            'userunknown' => ['550 - Requested action not taken: no such user here'],
          }
          boundaries = [Sisimai::RFC2045.boundary(mhead['content-type'], 1)]
          emailparts = Sisimai::RFC5322.part(mbody, boundaries)
          bodyslices = emailparts[0].split("\n")

          while e = bodyslices.shift do
            # Read error messages and delivery status lines from the head of the email to the previous
            # line of the beginning of the original message.
            if readcursor == 0
              # Beginning of the bounce message or delivery status part
              readcursor |= Indicators[:deliverystatus] if e.start_with?(markingsof[:message][0])
              next
            end
            next if (readcursor & Indicators[:deliverystatus]) == 0
            next if e.empty?

            # Message details:
            #   Subject: Test message
            #   Sent date: Wed Jun 12 02:21:53 GMT 2013
            #   MAIL FROM: *******@hg.example.com
            #   RCPT TO: *****@vtext.com
            v = dscontents[-1]
            if e.start_with?('  RCPT TO: ')
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                v = dscontents[-1]
              end

              v['recipient'] = e[11, e.size]
              recipients += 1
              next

            elsif e.start_with?('  MAIL FROM: ')
              #   MAIL FROM: *******@hg.example.com
              senderaddr = e[13, e.size] if senderaddr.empty?

            elsif e.start_with?('  Subject: ')
              #   Subject:
              subjecttxt = e[11, e.size] if subjecttxt.empty?
            else
              # 550 - Requested action not taken: no such user here
              v['diagnosis'] = e if e.include?(' - ')
            end
          end
        else
          # vzwpix.com
          startingof = { message: ['Message could not be delivered to mobile'] }
          messagesof = { 'userunknown' => ['No valid recipients for this MM'] }
          boundaries = [Sisimai::RFC2045.boundary(mhead['content-type'], 1)]
          emailparts = Sisimai::RFC5322.part(mbody, boundaries)
          bodyslices = emailparts[0].split("\n")

          while e = bodyslices.shift do
            # Read error messages and delivery status lines from the head of the email to the previous
            # line of the beginning of the original message.
            if readcursor == 0
              # Beginning of the bounce message or delivery status part
              readcursor |= Indicators[:deliverystatus] if e.start_with?(startingof[:message][0])
              next
            end
            next if (readcursor & Indicators[:deliverystatus]) == 0
            next if e.empty?

            # Original Message:
            # From: kijitora <kijitora@example.jp>
            # To: 0000000000@vzwpix.com
            # Subject: test for bounce
            # Date:  Wed, 20 Jun 2013 10:29:52 +0000
            v = dscontents[-1]
            if e.start_with?('To: ')
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = Sisimai::Address.s3s4(e[4, e.size])
              recipients += 1
              next

            elsif e.start_with?('From: ')
              # From: kijitora <kijitora@example.jp>
              senderaddr = Sisimai::Address.s3s4(e[4, e.size]) if senderaddr.empty?

            elsif e.start_with?('Subject: ')
              #   Subject:
              subjecttxt = e[9, e.size] if subjecttxt.empty?
            else
              # Message could not be delivered to mobile.
              # Error: No valid recipients for this MM
              v['diagnosis'] = Sisimai::String.sweep(e[7, e.size]) if e.start_with?('Error: ')
            end
          end
        end
        return nil unless recipients > 0

        # Set the value of "MAIL FROM:" and "From:"
        emailparts[1] << ('From: '    << senderaddr << "\n") if emailparts[1].include?("\nFrom: ") == false
        emailparts[1] << ('Subject: ' << subjecttxt << "\n") if emailparts[1].include?("\nSubject: ") == false

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          messagesof.each_key do |r|
            # Verify each regular expression of session errors
            next unless messagesof[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r
            break
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Verizon Wireless: https://www.verizonwireless.com'; end
    end
  end
end

