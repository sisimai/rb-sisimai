module Sisimai::Lhost
  # Sisimai::Lhost::Amavis parses a bounce email which created by
  # amavsid-new. Methods in the module are called from only Sisimai::Message.
  module Amavis
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Lhost/Amavis.pm
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      StartingOf = {
        message: ['The message '],
        rfc822:  ['Content-Type: text/rfc822-headers'],
      }.freeze

      def description; return 'amavisd-new: https://www.amavis.org/'; end
      def smtpagent;   return Sisimai::Lhost.smtpagent(self); end

      # Parse bounce messages from amavisd-new
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
        # From: "Content-filter at neko1.example.jp" <postmaster@neko1.example.jp>
        # Subject: Undeliverable mail, MTA-BLOCKED
        return nil unless mhead['from'].to_s.start_with?('"Content-filter at ')

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
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
            if e == StartingOf[:rfc822][0]
              readcursor |= Indicators[:'message-rfc822']
              next
            end
          end

          if readcursor & Indicators[:'message-rfc822'] > 0
            # message/rfc822 OR text/rfc822-headers part
            if e.empty?
              blanklines += 1
              break if blanklines > 1
              next
            end
            rfc822list << e
          else
            # message/delivery-status part
            next if (readcursor & Indicators[:deliverystatus]) == 0
            next if e.empty?
            next unless f = Sisimai::RFC1894.match(e)

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
                  dscontents << Sisimai::Lhost.DELIVERYSTATUS
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
              next unless fieldtable.key?(o[0])
              v[fieldtable[o[0]]] = o[2]

              next unless f == 1
              permessage[fieldtable[o[0]]] = o[2]
            end
          end # End of message/delivery-status
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }

          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].to_s.tr("\n", ' '))
          e['agent'] = self.smtpagent
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

