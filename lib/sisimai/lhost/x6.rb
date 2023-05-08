module Sisimai::Lhost
  # Sisimai::Lhost::X6 parses a bounce email which created by Unknown MTA #6. Methods in the module
  # are called from only Sisimai::Message.
  module X6
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['The attachment contains the original mail headers'].freeze
      StartingOf = { message: ['We had trouble delivering your message. Full details follow:'] }.freeze

      # Parse bounce messages from Unknown MTA #6
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      # @since v4.25.6
      def inquire(mhead, mbody)
        return nil unless mhead['subject'].start_with?('There was an error sending your mail')

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
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

          # We had trouble delivering your message. Full details follow:
          #
          # Subject: 'Nyaan'
          # Date: 'Thu, 29 Apr 2012 23:34:45 +0000'
          #          
          # 1 error(s):
          #
          # SMTP Server <mta2.example.jp> rejected recipient <kijitora@examplejp> 
          #   (Error following RCPT command). It responded as follows: [550 5.1.1 User unknown]v = dscontents[-1]
          v  = dscontents[-1]
          p1 = e.index('The following recipients returned permanent errors: ')
          p2 = e.index('SMTP Server <')

          if p1 == 0 || p2 == 0
            # SMTP Server <mta2.example.jp> rejected recipient <kijitora@examplejp> 
            # The following recipients returned permanent errors: neko@example.jp.
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end

            if p1 == 0
              # The following recipients returned permanent errors: neko@example.jp.
              p1 = e.index('errors: ')
              p2 = e.index(' ', p1 + 8)
              v['recipient'] = Sisimai::Address.s3s4(e[p1 + 8, p2 - p1 - 8])

            elsif p2 == 0
              # SMTP Server <mta2.example.jp> rejected recipient <kijitora@examplejp> 
              p1 = e.rindex('<')
              p2 = e.rindex('>')
              v['recipient'] = Sisimai::Address.s3s4(e[p1, p2 - p1])

            else
              next
            end

            v['diagnosis'] = e
            recipients += 1
          end
        end
        return nil unless recipients > 0

        require 'sisimai/smtp/command'
        dscontents.each do |e|
          if cv = Sisimai::SMTP::Command.find(e['diagnosis'])
            # ...(Error following RCPT command).
            e['command'] = cv
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Unknown MTA #6'; end
    end
  end
end

