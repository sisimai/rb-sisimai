module Sisimai::Lhost
  # Sisimai::Lhost::McAfee parses a bounce email which created by McAfee
  # Email Appliance. Methods in the module are called from only Sisimai::Message.
  module McAfee
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Lhost/McAfee.pm
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Type:[ ]message/rfc822|.freeze
      StartingOf = { message: ['--- The following addresses had delivery problems ---'] }.freeze
      ReFailures = {
        'userunknown' => %r{(?:
           [ ]User[ ][(].+[@].+[)][ ]unknown[.][ ]
          |550[ ]Unknown[ ]user[ ][^ ]+[@][^ ]+
          |550[ ][<].+?[@].+?[>][.]+[ ]User[ ]not[ ]exist
          |No[ ]such[ ]user
          )
        }x,
      }.freeze

      def description; return 'McAfee Email Appliance'; end
      def smtpagent;   return Sisimai::Lhost.smtpagent(self); end
      def headerlist;  return %w[x-nai-header]; end

      # Parse bounce messages from McAfee Email Appliance
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
      def make(mhead, mbody)
        return nil unless mhead['x-nai-header']
        return nil unless mhead['x-nai-header'].start_with?('Modified by McAfee ')
        return nil unless mhead['subject'] == 'Delivery Status'

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readslices = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        diagnostic = ''     # (String) Alternative diagnostic message
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email
          # to the previous line of the beginning of the original message.
          readslices << e # Save the current line for the next loop

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.include?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # Content-Type: text/plain; name="deliveryproblems.txt"
          #
          #    --- The following addresses had delivery problems ---
          #
          # <user@example.com>   (User unknown user@example.com)
          #
          # --------------Boundary-00=_00000000000000000000
          # Content-Type: message/delivery-status; name="deliverystatus.txt"
          #
          v = dscontents[-1]

          if cv = e.match(/\A[<]([^ ]+[@][^ ]+)[>][ \t]+[(](.+)[)]\z/)
            # <kijitora@example.co.jp>   (Unknown user kijitora@example.co.jp)
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            diagnostic = cv[2]
            recipients += 1

          elsif f = Sisimai::RFC1894.match(e)
            # "e" matched with any field defined in RFC3464
            o = Sisimai::RFC1894.field(e)
            unless o
              # Fallback code for empty value or invalid formatted value
              # - Original-Recipient: <kijitora@example.co.jp>
              if cv = e.match(/\AOriginal-Recipient:[ ]*([^ ]+)\z/)
                v['alias'] = Sisimai::Address.s3s4(cv[1])
              end
              next
            end
            next unless fieldtable.key?(o[0])
            v[fieldtable[o[0]]] = o[2]

          else
            # Continued line of the value of Diagnostic-Code field
            next unless readslices[-2].start_with?('Diagnostic-Code:')
            next unless cv = e.match(/\A[ \t]+(.+)\z/)
            v['diagnosis'] << ' ' << cv[1]
            readslices[-1] = 'Diagnostic-Code: ' << e
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'] || diagnostic)

          ReFailures.each_key do |r|
            # Verify each regular expression of session errors
            next unless e['diagnosis'] =~ ReFailures[r]
            e['reason'] = r
            break
          end
          e.each_key { |a| e[a] ||= '' }
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end

    end
  end
end

