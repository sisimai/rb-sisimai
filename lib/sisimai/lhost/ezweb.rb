module Sisimai::Lhost
  # Sisimai::Lhost::EZweb decodes a bounce email which created by au EZweb https://www.au.com/mobile/.
  # Methods in the module are called from only Sisimai::Message.
  module EZweb
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['--------------------------------------------------', 'Content-Type: message/rfc822'].freeze
      MarkingsOf = { message: ['The user(s) ', 'Your message ', 'Each of the following', '<'] }.freeze
      ReFailures = {
        # notaccept: ['The following recipients did not receive this message:'],
        'mailboxfull' => ['The user(s) account is temporarily over quota'],
        'suspend' => [
          # http://www.naruhodo-au.kddi.com/qa3429203.html
          # The recipient may be unpaid user...?
          'The user(s) account is disabled.',
          'The user(s) account is temporarily limited.',
        ],
        'expired' => [
          # Your message was not delivered within 0 days and 1 hours.
          # Remote host is not responding.
          'Your message was not delivered within ',
        ],
        'onhold' => ['Each of the following recipients was rejected by a remote mail server'],
      }.freeze

      # @abstract Decodes the bounce message from au EZweb
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        match  = 0
        match += 1 if mhead['from'].include?('Postmaster@ezweb.ne.jp')
        match += 1 if mhead['from'].include?('Postmaster@au.com')
        match += 1 if mhead['subject'] == 'Mail System Error - Returned Mail'
        match += 1 if mhead['received'].any? { |a| a.include?('ezweb.ne.jp (EZweb Mail) with') }
        match += 1 if mhead['received'].any? { |a| a.include?('.au.com (') }
        if mhead['message-id']
          match += 1 if mhead['message-id'].end_with?('.ezweb.ne.jp>', '.au.com>')
        end
        return nil if match < 2

        fieldtable = Sisimai::RFC1894.FIELDTABLE
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        rxmessages = []; ReFailures.each_value { |a| rxmessages << a }
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if MarkingsOf[:message].any? { |a| e.include?(a) }
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # The user(s) account is disabled.
          #
          # <***@ezweb.ne.jp>: 550 user unknown (in reply to RCPT TO command)
          #
          #  -- OR --
          # Each of the following recipients was rejected by a remote
          # mail server.
          #
          #    Recipient: <******@ezweb.ne.jp>
          #    >>> RCPT TO:<******@ezweb.ne.jp>
          #    <<< 550 <******@ezweb.ne.jp>: User unknown
          v = dscontents[-1]

          if Sisimai::String.aligned(e, ['<', '@', '>']) && (e.include?('Recipient: <') || e.start_with?('<'))
            #    Recipient: <******@ezweb.ne.jp> OR <***@ezweb.ne.jp>: 550 user unknown ...
            p1 = e.index('<') || -1
            p2 = e.index('>') || -1

            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = Sisimai::Address.s3s4(e[p1, p2 - p1])
            recipients += 1

          elsif f = Sisimai::RFC1894.match(e)
            # "e" matched with any field defined in RFC3464
            next unless o = Sisimai::RFC1894.field(e)
            next unless fieldtable[o[0]]
            v[fieldtable[o[0]]] = o[2]

          else
            # The line does not begin with a DSN field defined in RFC3464
            next if Sisimai::String.is_8bit(e)
            if e.include?('>>> ')
              #    >>> RCPT TO:<******@ezweb.ne.jp>
              v['command'] = Sisimai::SMTP::Command.find(e) || ''
            else
              # Check error message
              if rxmessages.any? { |messages| messages.any? { |message| e.include?(message) } }
                # Check with regular expressions of each error
                v['diagnosis'] ||= ''
                v['diagnosis'] << ' ' << e
              else
                # >>> 550
                v['alterrors'] ||= ''
                v['alterrors'] << ' ' << e
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          unless e['alterrors'].to_s.empty?
            # Copy alternative error message
            e['diagnosis'] ||= e['alterrors']
            if e['diagnosis'].start_with?('-') || e['diagnosis'].end_with?('__')
              # Override the value of diagnostic code message
              e['diagnosis'] = e['alterrors'] unless e['alterrors'].empty?
            end
            e.delete('alterrors')
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''

          if mhead['x-spasign'].to_s == 'NG'
            # Content-Type: text/plain; ..., X-SPASIGN: NG (spamghetti, au by EZweb)
            # Filtered recipient returns message that include 'X-SPASIGN' header
            e['reason'] = 'filtered'
          else
            if e['command'] == 'RCPT'
              # set "userunknown" when the remote server rejected after RCPT command.
              e['reason'] = 'userunknown'
            else
              # SMTP command is not RCPT
              catch :SESSION do
                ReFailures.each_key do |r|
                  # Try to match with each session error message
                  ReFailures[r].each do |rr|
                    # Check each error message pattern
                    next unless e['diagnosis'].include?(rr)
                    e['reason'] = r
                    throw :SESSION
                  end
                end
              end

            end
          end
          next if e['reason']
          next if e['recipient'].end_with?('@ezweb.ne.jp', '@au.com')
          e['reason'] = 'userunknown'
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'au EZweb: http://www.au.kddi.com/mobile/'; end
    end
  end
end

