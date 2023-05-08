module Sisimai::Lhost
  # Sisimai::Lhost::Activehunter parses a bounce email which created by TransWARE Active!hunter.
  # Methods in the module are called from only Sisimai::Message.
  module Activehunter
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['Content-Type: message/rfc822'].freeze
      StartingOf = { message: ['  ----- The following addresses had permanent fatal errors -----'] }.freeze

      # Parse bounce messages from TransWARE Active!hunter
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # :from    => %r/\A"MAILER-DAEMON"/,
        # :subject => %r/FAILURE NOTICE :/,
        return nil unless mhead['x-ahmailid']

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
            readcursor |= Indicators[:deliverystatus] if e == StartingOf[:message][0]
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          #  ----- The following addresses had permanent fatal errors -----
          #
          # >>> kijitora@example.org <kijitora@example.org>
          #
          #  ----- Transcript of session follows -----
          # 550 sorry, no mailbox here by that name (#5.1.1 - chkusr)
          v = dscontents[-1]

          if e.start_with?('>>> ') && e.index('@') > 1
            # >>> kijitora@example.org <kijitora@example.org>
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = Sisimai::Address.s3s4(e[e.index('<'), e.size])
            v['diagnosis'] = ''
            recipients += 1
          else
            #  ----- Transcript of session follows -----
            # 550 sorry, no mailbox here by that name (#5.1.1 - chkusr)
            next if e[0, 1].ord <  48
            next if e[0, 1].ord > 122
            next unless v['diagnosis'].empty?
            v['diagnosis'] = e
          end
        end
        return nil unless recipients > 0

        dscontents.each { |e| e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) }
        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'TransWARE Active!hunter'; end
    end
  end
end

