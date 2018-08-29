module Sisimai::Bite::Email
  # Sisimai::Bite::Email::X5 parses a bounce email which created by Unknown
  # MTA #5. Methods in the module are called from only Sisimai::Message.
  module X5
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/X5.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['Content-Type: message/delivery-status'],
        rfc822:  ['Content-Type: message/rfc822'],
      }.freeze

      def description; return 'Unknown MTA #5'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Unknown MTA #5
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
        match  = 0
        match += 1 if mhead['to'].to_s.include?('NotificationRecipients')
        if mhead['from'].include?('TWFpbCBEZWxpdmVyeSBTdWJzeXN0ZW0')
          # From: "=?iso-2022-jp?B?TWFpbCBEZWxpdmVyeSBTdWJzeXN0ZW0=?=" <...>
          #       Mail Delivery Subsystem
          mhead['from'].split(' ').each do |f|
            # Check each element of From: header
            next unless Sisimai::MIME.is_mimeencoded(f)
            match += 1 if Sisimai::MIME.mimedecode([f]).include?('Mail Delivery Subsystem')
            break
          end
        end

        if Sisimai::MIME.is_mimeencoded(mhead['subject'])
          # Subject: =?iso-2022-jp?B?UmV0dXJuZWQgbWFpbDogVXNlciB1bmtub3du?=
          plain = Sisimai::MIME.mimedecode([mhead['subject']])
          match += 1 if plain.include?('Mail Delivery Subsystem')
        end
        return nil if match < 2

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e.start_with?(StartingOf[:message][0])
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e.start_with?(StartingOf[:rfc822][0])
              readcursor |= Indicators[:'message-rfc822']
              next
            end
          end

          if readcursor & Indicators[:'message-rfc822'] > 0
            # Before "message/rfc822"
            next if e.empty?
            v = dscontents[-1]

            if cv = e.match(/\AFinal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
              # Final-Recipient: RFC822; kijitora@example.jp
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              recipients += 1

            elsif cv = e.match(/\AX-Actual-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/) ||
                       e.match(/\AOriginal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
              # X-Actual-Recipient: RFC822; kijitora@example.co.jp
              # Original-Recipient: rfc822;kijitora@example.co.jp
              v['alias'] = cv[1]

            elsif cv = e.match(/\AAction:[ ]*(.+)\z/)
              # Action: failed
              v['action'] = cv[1].downcase

            elsif cv = e.match(/\AStatus:[ ]*(\d[.]\d+[.]\d+)/)
              # Status: 5.1.1
              v['status'] = cv[1]

            elsif cv = e.match(/\AReporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
              # Reporting-MTA: dns; mx.example.jp
              v['lhost'] = cv[1].downcase

            elsif cv = e.match(/\ARemote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
              # Remote-MTA: DNS; mx.example.jp
              v['rhost'] = cv[1].downcase

            elsif cv = e.match(/\ALast-Attempt-Date:[ ]*(.+)\z/)
              # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
              v['date'] = cv[1]
            else
              # Get an error message from Diagnostic-Code: field
              if cv = e.match(/\ADiagnostic-Code:[ ]*(.+?);[ ]*(.+)\z/)
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                v['spec'] = cv[1].downcase
                v['diagnosis'] = cv[2]

              elsif p.start_with?('Diagnostic-Code:') && cv = e.match(/\A[ \t]+(.+)\z/)
                # Continued line of the value of Diagnostic-Code header
                v['diagnosis'] << ' ' << cv[1]
                havepassed[-1] = 'Diagnostic-Code: ' << e
              end
            end
          else
            # After "message/rfc822"
            next unless recipients > 0
            next if (readcursor & Indicators['deliverystatus']) == 0

            if e.empty?
              blanklines += 1
              break if blanklines > 1
              next
            end
            rfc822list << e
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']       = self.smtpagent
          e['diagnosis'] ||= Sisimai::String.sweep(e['diagnosis'])
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

