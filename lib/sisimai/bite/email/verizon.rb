module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Verizon parses a bounce email which created by
  # Verizon Wireless.
  # Methods in the module are called from only Sisimai::Message.
  module Verizon
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Verizon.pm
      require 'sisimai/bite/email'

      Re0 = {
        :'received'  => %r/by .+[.]vtext[.]com /,
        :'vtext.com' => {
          :'from' => %r/\Apost_master[@]vtext[.]com\z/,
        },
        :'vzwpix.com' => {
          :'from'    => %r/[<]?sysadmin[@].+[.]vzwpix[.]com[>]?\z/,
          :'subject' => %r/Undeliverable Message/,
        },
      }.freeze
      Indicators = Sisimai::Bite::Email.INDICATORS

      def description; return 'Verizon Wireless: http://www.verizonwireless.com'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end
      def pattern
        return {
          :from => %r/(?:\Apost_master[@]vtext[.]com|[<]?sysadmin[@].+[.]vzwpix[.]com[>]?)\z/,
          :subject => Re0[:'vzwpix.com'][:subject],
        }
      end

      # Parse bounce messages from Verizon
      # @param         [Hash] mhead       Message headers of a bounce email
      # @options mhead [String] from      From header
      # @options mhead [String] date      Date header
      # @options mhead [String] subject   Subject header
      # @options mhead [Array]  received  Received headers
      # @options mhead [String] others    Other required headers
      # @param         [String] mbody     Message body of a bounce email
      # @return        [Hash, Nil]        Bounce data list and message/rfc822
      #                                   part or nil if it failed to parse or
      #                                   the arguments are missing
      def scan(mhead, mbody)
        return nil unless mhead
        return nil unless mbody

        match = -1
        while true
          # Check the value of "From" header
          break unless mhead['received'].find { |a| a =~ Re0[:received] }
          match = 1 if mhead['from'] =~ Re0[:'vtext.com'][:from]
          match = 0 if mhead['from'] =~ Re0[:'vzwpix.com'][:from]
          break
        end
        return nil if match < 0

        require 'sisimai/mime'
        require 'sisimai/address'
        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        senderaddr = ''     # (String) Sender address in the message body
        subjecttxt = ''     # (String) Subject of the original message

        re1        = {}     # (Ref->Hash) Delimiter patterns
        reFailure  = {}     # (Ref->Hash) Error message patterns
        boundary00 = ''     # (String) Boundary string
        v = nil

        if match == 1
          # vtext.com
          re1 = {
            :begin  => %r/\AError:[ \t]/,
            :rfc822 => %r/\A__BOUNDARY_STRING_HERE__\z/,
            :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
          }
          reFailure = {
            # The attempted recipient address does not exist.
            userunknown: %r/550[ ][-][ ]Requested[ ]action[ ]not[ ]taken:[ ]no[ ]such[ ]user[ ]here/x,
          }
          boundary00 = Sisimai::MIME.boundary(mhead['content-type']) || ''

          if boundary00.size > 0
            # Convert to regular expression
            re1['rfc822'] = Regexp.new('\A' << Regexp.escape('--' << boundary00 << '--') << '\z')
          end

          hasdivided.each do |e|
            if readcursor.zero?
              # Beginning of the bounce message or delivery status part
              if e =~ re1[:begin]
                readcursor |= Indicators[:deliverystatus]
                next
              end
            end

            if (readcursor & Indicators[:'message-rfc822']).zero?
              # Beginning of the original message part
              if e =~ re1[:rfc822]
                readcursor |= Indicators[:'message-rfc822']
                next
              end
            end

            if readcursor & Indicators[:'message-rfc822'] > 0
              # After "message/rfc822"
              if e.empty?
                blanklines += 1
                break if blanklines > 1
                next
              end
              rfc822list << e

            else
              # Before "message/rfc822"
              next if (readcursor & Indicators[:deliverystatus]).zero?
              next if e.empty?

              # Message details:
              #   Subject: Test message
              #   Sent date: Wed Jun 12 02:21:53 GMT 2013
              #   MAIL FROM: *******@hg.example.com
              #   RCPT TO: *****@vtext.com
              v = dscontents[-1]
              if cv = e.match(/\A[ \t]+RCPT TO: (.*)\z/)
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Bite.DELIVERYSTATUS
                  v = dscontents[-1]
                end

                v['recipient'] = cv[1]
                recipients += 1
                next

              elsif cv = e.match(/\A[ \t]+MAIL FROM:[ \t](.+)\z/)
                #   MAIL FROM: *******@hg.example.com
                senderaddr = cv[1] if senderaddr.empty?

              elsif cv = e.match(/\A[ \t]+Subject:[ \t](.+)\z/)
                #   Subject:
                subjecttxt = cv[1] if subjecttxt.empty?

              else
                # 550 - Requested action not taken: no such user here
                v['diagnosis'] = e if e =~ /\A(\d{3})[ \t][-][ \t](.*)\z/
              end
            end
          end

        else
          # vzwpix.com
          re1 = {
            :begin  => %r/\AMessage could not be delivered to mobile/,
            :rfc822 => %r/\A__BOUNDARY_STRING_HERE__\z/,
            :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
          }
          reFailure = {
            userunknown: %r/No[ ]valid[ ]recipients[ ]for[ ]this[ ]MM/x,
          }
          boundary00 = Sisimai::MIME.boundary(mhead['content-type'])
          if boundary00.size > 0
            # Convert to regular expression
            re1['rfc822'] = Regexp.new('\A' << Regexp.escape('--' << boundary00 << '--') << '\z')
          end

          hasdivided.each do |e|
            if readcursor.zero?
              # Beginning of the bounce message or delivery status part
              if e =~ re1[:begin]
                readcursor |= Indicators[:deliverystatus]
                next
              end
            end

            if (readcursor & Indicators[:'message-rfc822']).zero?
              # Beginning of the original message part
              if e =~ re1[:rfc822]
                readcursor |= Indicators[:'message-rfc822']
                next
              end
            end

            if readcursor & Indicators[:'message-rfc822'] > 0
              # After "message/rfc822"
              if e.empty?
                blanklines += 1
                break if blanklines > 1
                next
              end
              rfc822list << e

            else
              # Before "message/rfc822"
              next if (readcursor & Indicators[:deliverystatus]).zero?
              next if e.empty?

              # Original Message:
              # From: kijitora <kijitora@example.jp>
              # To: 0000000000@vzwpix.com
              # Subject: test for bounce
              # Date:  Wed, 20 Jun 2013 10:29:52 +0000
              v = dscontents[-1]
              if cv = e.match(/\ATo:[ \t]+(.*)\z/)
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Bite.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = Sisimai::Address.s3s4(cv[1])
                recipients += 1
                next

              elsif cv = e.match(/\AFrom:[ \t](.+)\z/)
                # From: kijitora <kijitora@example.jp>
                senderaddr = Sisimai::Address.s3s4(cv[1]) if senderaddr.empty?

              elsif cv = e.match(/\ASubject:[ \t](.+)\z/)
                #   Subject:
                subjecttxt = cv[1] if subjecttxt.empty?

              else
                # Message could not be delivered to mobile.
                # Error: No valid recipients for this MM
                v['diagnosis'] = e if e =~ /\AError:[ \t]+(.+)\z/
              end
            end
          end
        end

        return nil if recipients.zero?

        if !rfc822list.find { |a| a.start_with?('From: ') }
          # Set the value of "MAIL FROM:" or "From:"
          rfc822list << ('From: ' << senderaddr)

        elsif !rfc822list.find { |a| a.start_with?('Subject: ') }
          # Set the value of "Subject:"
          rfc822list << ('Subject: ' << subjecttxt)
        end

        require 'sisimai/string'
        dscontents.map do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          reFailure.each_key do |r|
            # Verify each regular expression of session errors
            next unless e['diagnosis'] =~ reFailure[r]
            e['reason'] = r.to_s
            break
          end
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

