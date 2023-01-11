module Sisimai
  # Sisimai::RFC3464 - bounce mail parser class for Fallback.
  module RFC3464
    class << self
      require 'sisimai/lhost'
      require 'sisimai/address'
      require 'sisimai/rfc1894'

      # http://tools.ietf.org/html/rfc3464
      Indicators = Sisimai::Lhost.INDICATORS
      StartingOf = {
        message: [
          'content-type: message/delivery-status',
          'content-type: message/disposition-notification',
          'content-type: text/plain; charset=',
          'the original message was received at ',
          'this report relates to your message',
          'your message could not be delivered',
          'your message was not delivered to ',
          'your message was not delivered to the following recipients',
        ],
        rfc822: [
          'content-type: message/rfc822',
          'content-type: text/rfc822-headers',
          'return-path: <'
        ],
      }.freeze
      ReadUntil0 = [
        # Stop reading when the following string have appeared at the first of a line
        'a copy of the original message below this line:',
        'content-type: message/delivery-status',
        'for further assistance, please contact ',
        'here is a copy of the first part of the message',
        'received:',
        'received-from-mta:',
        'reporting-mta:',
        'reporting-ua:',
        'return-path:',
        'the non-delivered message is attached to this message',
      ].freeze
      ReadUntil1 = [
        # Stop reading when the following string have appeared in a line
        'attachment is a copy of the message',
        'below is a copy of the original message:',
        'below this line is a copy of the message',
        'message contains ',
        'message text follows: ',
        'original message follows',
        'the attachment contains the original mail headers',
        'the first ',
        'unsent message below',
        'your message reads (in part):',
      ].freeze
      ReadAfter0 = [
        # Do not read before the following strings
        '	the postfix ',
        'a summary of the undelivered message you sent follows:',
        'the following is the error message',
        'the message that you sent was undeliverable to the following',
        'your message was not delivered to ',
      ].freeze
      DoNotRead0 = ['   -----', ' -----', '--', '|--', '*'].freeze
      DoNotRead1 = ['mail from:', 'message-id:', '  from: '].freeze
      ReadEmail0 = [' ', '"', '<',].freeze
      ReadEmail1 = [
        # There is an email address around the following strings
        'address:',
        'addressed to',
        'could not be delivered to:',
        'delivered to',
        'delivery failed:',
        'did not reach the following recipient:',
        'error-for:',
        'failed recipient:',
        'failed to deliver to',
        'intended recipient:',
        'mailbox is full:',
        'recipient:',
        'rcpt to:',
        'smtp server <',
        'the following recipients returned permanent errors:',
        'the following addresses had permanent errors',
        'the following message to',
        'to: ',
        'unknown user:',
        'unable to deliver mail to the following recipient',
        'undeliverable to',
        'undeliverable address:',
        'you sent mail to',
        'your message has encountered delivery problems to the following recipients:',
        'was automatically rejected',
        'was rejected due to',
      ].freeze

      # Detect an error for RFC3464
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        bodyslices = mbody.scrub('?').split("\n")
        readslices = ['']
        rfc822text = ''   # (String) message/rfc822 part text
        maybealias = nil  # (String) Original-Recipient Field
        lowercased = ''   # (String) Lowercased each line of the loop
        blanklines = 0    # (Integer) The number of blank lines
        readcursor = 0    # (Integer) Points the current cursor position
        recipients = 0    # (Integer) The number of 'Final-Recipient' header
        itisbounce = false
        connheader = {
          'date'  => nil, # The value of Arrival-Date header
          'rhost' => nil, # The value of Reporting-MTA header
          'lhost' => nil, # The value of Received-From-MTA header
        }
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          readslices << e # Save the current line for the next loop
          lowercased = e.downcase

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if StartingOf[:message].any? { |a| lowercased.start_with?(a) }
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if StartingOf[:rfc822].any? { |a| lowercased == a }
              readcursor |= Indicators[:'message-rfc822']
              next
            end
          end

          if readcursor & Indicators[:'message-rfc822'] > 0
            # Inside of the original message part
            if e.empty?
              blanklines += 1
              break if blanklines > 1
              next
            end
            rfc822text << e << "\n"
          else
            # Error message part
            next unless readcursor & Indicators[:deliverystatus] > 0
            next if e.empty?

            v = dscontents[-1]
            if f = Sisimai::RFC1894.match(e)
              # "e" matched with any field defined in RFC3464
              next unless o = Sisimai::RFC1894.field(e)

              if o[-1] == 'addr'
                # Final-Recipient: rfc822; kijitora@example.jp
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                if o[0] == 'final-recipient' || o[0] == 'original-recipient'
                  # Final-Recipient: rfc822; kijitora@example.jp
                  if o[0] == 'original-recipient'
                    # Original-Recipient: ...
                    maybealias = o[2]
                  else
                    # Final-Recipient: ...
                    x = v['recipient'] || ''
                    y = Sisimai::Address.s3s4(o[2])
                    y = maybealias unless Sisimai::Address.is_emailaddress(y)

                    if !x.empty? && x != y
                      # There are multiple recipient addresses in the message body.
                      dscontents << Sisimai::Lhost.DELIVERYSTATUS
                      v = dscontents[-1]
                    end
                    v['recipient'] = y
                    recipients  += 1
                    itisbounce ||= true

                    v['alias'] ||= maybealias
                    maybealias = nil
                  end
                elsif o[0] == 'x-actual-recipient'
                  # X-Actual-Recipient: RFC822; |IFS=' ' && exec procmail -f- || exit 75 ...
                  # X-Actual-Recipient: rfc822; kijitora@neko.example.jp 
                  v['alias'] = o[2] unless o[2].include?(' ')
                end
              elsif o[-1] == 'code'
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                v['spec']      = o[1]
                v['diagnosis'] = o[2]
              else
                # Other DSN fields defined in RFC3464
                next unless fieldtable[o[0]]
                v[fieldtable[o[0]]] = o[2]

                next unless f == 1
                permessage[fieldtable[o[0]]] = o[2]
              end
            else
              # The line did not match with any fields defined in RFC3464
              if cv = e.match(/\ADiagnostic-Code:[ ]([^;]+)\z/)
                # There is no value of "diagnostic-type" such as Diagnostic-Code: 554 ...
                v['diagnosis'] = cv[1]
              elsif cv = e.match(/\AStatus:[ ](\d{3}[ ]+.+)\z/)
                # Status: 553 Exceeded maximum inbound message size
                v['alterrors'] = cv[1]
              elsif readslices[-2].start_with?('Diagnostic-Code:') && cv = e.match(/\A[ ]+(.+)\z/)
                # Continued line of the value of Diagnostic-Code header
                v['diagnosis'] << ' ' << cv[1]
                readslices[-1] = 'Diagnostic-Code: ' << e
              else
                # Get error messages which is written in the message body directly
                next if e.start_with?(' ', '	')
                next unless e =~ /\A(?:[45]\d\d[ ]+|[<][^@]+[@][^@]+[>]:?[ ]+)/

                v['alterrors'] ||= ' '
                v['alterrors']  << ' ' << e
              end
            end
          end # End of if: rfc822
        end

        # -----------------------------------------------------------------------------------------
        while true
          # Fallback, parse entire message body
          break if recipients > 0

          # Failed to get a recipient address at code above
          returnpath = (mhead['return-path'] || '').downcase
          headerfrom = (mhead['from']        || '').downcase
          errortitle = (mhead['subject']     || '').downcase
          patternsof = {
            'from'        => ['postmaster@', 'mailer-daemon@', 'root@'],
            'return-path' => ['<>', 'mailer-daemon'],
            'subject'     => ['delivery fail', 'delivery report', 'failure notice', 'mail delivery',
                              'mail failed', 'mail error', 'non-delivery', 'returned mail',
                              'undeliverable mail', 'warning: '],
          }

          match   = nil
          match ||= patternsof['from'].any?        { |v| headerfrom.include?(v) }
          match ||= patternsof['subject'].any?     { |v| errortitle.include?(v) }
          match ||= patternsof['return-path'].any? { |v| returnpath.include?(v) }
          break unless match

          b = dscontents[-1]
          hasmatched = 0  # There may be an email address around the line
          readslices = [] # Previous line of this loop

          ReadAfter0.each do |e|
            # Cut strings from the begining of "mbody" to the strings defined in ReadAfter0
            i = mbody.downcase.index(e)
            next unless i
            mbody = mbody[i, mbody.size - i]
          end
          lowercased = mbody.downcase
          bodyslices = mbody.split("\n")

          while e = bodyslices.shift do
            # Get the recipient's email address and error messages.
            next if e.empty?
            hasmatched = 0
            lowercased = e.downcase
            readslices << lowercased

            break if StartingOf[:rfc822].include?(lowercased)
            break if ReadUntil0.any? { |v| lowercased.start_with?(v) }
            break if ReadUntil1.any? { |v| lowercased.include?(v) }
            next  if DoNotRead0.any? { |v| lowercased.start_with?(v) }
            next  if DoNotRead1.any? { |v| lowercased.include?(v) }

            while true do
              # There is an email address with an error message at this line(1)
              break unless ReadEmail0.any? { |v| lowercased.start_with?(v) }
              break unless lowercased.include?('@')

              hasmatched = 1
              break
            end

            while true do
              # There is an email address with an error message at this line(2)
              break if hasmatched > 0
              break unless ReadEmail1.any? { |v| lowercased.include?(v) }
              break unless lowercased.include?('@')

              hasmatched = 2
              break
            end

            while true do
              # There is an email address without an error message at this line
              break if hasmatched > 0
              break if readslices.size < 2
              break unless ReadEmail1.any? { |v| readslices[-2].include?(v) }
              break unless lowercased.include?('@') # Must contain '@'
              break unless lowercased.include?('.') # Must contain '.'
              break if     lowercased.include?('$')

              hasmatched = 3
              break
            end

            if hasmatched > 0 && lowercased.include?('@')
              # May be an email address
              w = e.split(' ')
              x = b['recipient'] || ''
              y = ''

              w.each do |ee|
                # Find an email address (including "@")
                next unless ee.include?('@')
                y = Sisimai::Address.s3s4(ee)
                next unless Sisimai::Address.is_emailaddress(y)
                break
              end
              
              if !x.empty? && x != y
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                b = dscontents[-1]
              end
              b['recipient'] = y
              recipients += 1
              itisbounce ||= true

            elsif cv = e.match(/[(](?:expanded|generated)[ ]from:?[ ]([^@]+[@][^@]+)[)]/)
              # (expanded from: neko@example.jp)
              b['alias'] = Sisimai::Address.s3s4(cv[1])
            end
            b['diagnosis'] ||= ''
            b['diagnosis']  << ' ' << e
          end

          break
        end
        return nil unless itisbounce

        if recipients == 0 && cv = rfc822text.match(/^To:[ ](.+)/)
          # Try to get a recipient address from "To:" header of the original message
          if r = Sisimai::Address.find(cv[1], true)
            # Found a recipient address
            dscontents << Sisimai::Lhost.DELIVERYSTATUS if dscontents.size == recipients
            b = dscontents[-1]
            b['recipient'] = r[0][:address]
            recipients += 1
          end
        end
        return nil unless recipients > 0

        require 'sisimai/smtp/command'
        require 'sisimai/mda'
        mdabounced = Sisimai::MDA.inquire(mhead, mbody)
        dscontents.each do |e|
          # Set default values if each value is empty.
          connheader.each_key { |a| e[a] ||= connheader[a] || '' }

          if e['alterrors']
            # Copy alternative error message
            unless e['alterrors'].empty?
              e['diagnosis'] ||= e['alterrors']
              if e['diagnosis'].start_with?('-') || e['diagnosis'].end_with?('__')
                # Override the value of diagnostic code message
                e['diagnosis'] = e['alterrors']
              end
              e.delete('alterrors')
            end
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''

          if mdabounced
            # Make bounce data by the values returned from Sisimai::MDA.inquire()
            e['agent']     = mdabounced['mda'] || 'RFC3464'
            e['reason']    = mdabounced['reason'] || 'undefined'
            e['diagnosis'] = mdabounced['message'] unless mdabounced['message'].empty?
            e['command']   = nil
          end

          e['date']    ||= mhead['date']
          e['status']  ||= Sisimai::SMTP::Status.find(e['diagnosis']) || ''
          e['command'] ||= Sisimai::SMTP::Command.find(e['diagnosis'])
        end

        return { 'ds' => dscontents, 'rfc822' => rfc822text }
      end
      def description; 'Fallback Module for MTAs'; end
    end
  end
end
