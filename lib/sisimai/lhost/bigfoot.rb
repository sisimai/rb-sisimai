module Sisimai::Lhost
  # Sisimai::Lhost::Bigfoot decodes a bounce email which created by Bigfoot https://www.bigfoot.com/.
  # Methods in the module are called from only Sisimai::Message.
  module Bigfoot
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['Content-Type: message/partial'].freeze
      MarkingsOf = { message: '   ----- Transcript of session follows -----' }.freeze

      # @abstract Decodes the bounce message from Bigfoot
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        # :subject  => %r/\AReturned mail: /,
        match  = 0
        match += 1 if mhead['from'].include?('@bigfoot.com>')
        match += 1 if mhead['received'].any? { |a| a.include?('.bigfoot.com') }
        return nil unless match > 0

        require 'sisimai/smtp/command'
        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readslices = ['']
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        thecommand = ''     # (String) SMTP Command name begin with the string '>>>'
        esmtpreply = ''     # (String) Reply from remote server on SMTP session
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          readslices << e # Save the current line for the next loop

          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(MarkingsOf[:message])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

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
              next unless fieldtable[o[0]]
              v[fieldtable[o[0]]] = o[2]

              next unless f
              permessage[fieldtable[o[0]]] = o[2]
            end
          else
            # The line does not begin with a DSN field defined in RFC3464
            unless e.start_with?(' ')
              #    ----- Transcript of session follows -----
              # >>> RCPT TO:<destinaion@example.net>
              # <<< 553 Invalid recipient destinaion@example.net (Mode: normal)
              if e.start_with?('>>> ')
                # >>> DATA
                thecommand = Sisimai::SMTP::Command.find(e)
              elsif e.start_with?('<<< ')
                # <<< Response
                esmtpreply = e[4, e.size - 4]
              end
            else
              # Continued line of the value of Diagnostic-Code field
              next unless readslices[-2].start_with?('Diagnostic-Code:')
              next unless e.start_with?(' ')
              v['diagnosis'] << ' ' << Sisimai::String.sweep(e[1, e.size])
              readslices[-1] = 'Diagnostic-Code: ' << e
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['command']   = thecommand || ''
          if e['command'].empty?
            e['command'] = 'EHLO' unless esmtpreply.empty?
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Bigfoot: http://www.bigfoot.com'; end
    end
  end
end

