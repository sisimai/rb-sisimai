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

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
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
            # Beginning of the bounce message or message/delivery-status part
            if e.start_with?(StartingOf[:message][0])
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part(message/rfc822)
            if e.start_with?(StartingOf[:rfc822][0])
              readcursor |= Indicators[:'message-rfc822']
              next
            end
          end

          if readcursor & Indicators[:'message-rfc822'] > 0
            # message/delivery-status part
            next if e.empty?
            v = dscontents[-1]

            if f = Sisimai::RFC1894.match(e)
              # "e" matched with any field defined in RFC3464
              next unless o = Sisimai::RFC1894.field(e)
              v = dscontents[-1]

              if o[-1] == 'addr'
                # Final-Recipient: rfc822; kijitora@example.jp
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                if o[0] == 'final-recipient'
                  # Final-Recipient: rfc822; kijitora@example.jp
                  if v['recipient']
                    # There are multiple recipient addresses in the message body.
                    dscontents << Sisimai::Bite.DELIVERYSTATUS
                    v = dscontents[-1]
                  end
                  v['recipient'] = o[2]
                  recipients += 1
                else
                  # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                  v['alias'] = o[2]
                end
              elsif o[-1] == 'code'
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                v['spec'] = o[1]
                v['diagnosis'] = o[2]
              else
                # Other DSN fields defined in RFC3464
                next unless fieldtable.key?(o[0].to_sym)
                v[fieldtable[o[0].to_sym]] = o[2]
              end
            else
              # Continued line of the value of Diagnostic-Code field
              next unless p.start_with?('Diagnostic-Code:')
              next unless cv = e.match(/\A[ \t]+(.+)\z/)
              v['diagnosis'] << ' ' << cv[1]
              havepassed[-1] = 'Diagnostic-Code: ' << e
            end
          else
            # message/rfc822 OR text/rfc822-headers part
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

