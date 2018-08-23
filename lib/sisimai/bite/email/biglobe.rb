module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Biglobe parses a bounce email which created by BIGLOBE.
  # Methods in the module are called from only Sisimai::Message.
  module Biglobe
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Biglobe.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['   ----- The following addresses had delivery problems -----'],
        error:   ['   ----- Non-delivered information -----'],
        rfc822:  ['Content-Type: message/rfc822'],
      }.freeze
      MessagesOf = {
        filtered:    ['Mail Delivery Failed... User unknown'],
        mailboxfull: ["The number of messages in recipient's mailbox exceeded the local limit."],
      }.freeze

      def description; return 'BIGLOBE: http://www.biglobe.ne.jp'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Biglobe
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
        return nil unless mhead['from'] =~ /postmaster[@](?:biglobe|inacatv|tmtv|ttv)[.]ne[.]jp/
        return nil unless mhead['subject'].start_with?('Returned mail:')

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = hasdivided.shift do
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e == StartingOf[:message][0]
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e == StartingOf[:rfc822][0]
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
            next if (readcursor & Indicators[:deliverystatus]) == 0
            next if e.empty?

            # This is a MIME-encapsulated message.
            #
            # ----_Biglobe000000/00000.biglobe.ne.jp
            # Content-Type: text/plain; charset="iso-2022-jp"
            #
            #    ----- The following addresses had delivery problems -----
            # ********@***.biglobe.ne.jp
            #
            #    ----- Non-delivered information -----
            # The number of messages in recipient's mailbox exceeded the local limit.
            #
            # ----_Biglobe000000/00000.biglobe.ne.jp
            # Content-Type: message/rfc822
            #
            v = dscontents[-1]

            if cv = e.match(/\A([^ ]+[@][^ ]+)\z/)
              #    ----- The following addresses had delivery problems -----
              # ********@***.biglobe.ne.jp
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end

              r = Sisimai::Address.s3s4(cv[1])
              if Sisimai::RFC5322.is_emailaddress(r)
                v['recipient'] = r
                recipients += 1
              end
            else
              next if e =~ /\A[^\w]/
              v['diagnosis'] ||= ''
              v['diagnosis'] << e + ' '
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          MessagesOf.each_key do |r|
            # Verify each regular expression of session errors
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
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

