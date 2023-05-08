module Sisimai::Lhost
  # Sisimai::Lhost::X1 parses a bounce email which created by Unknown MTA #1. Methods in the module
  # are called from only Sisimai::Message.
  module X1
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['Received: from '].freeze
      MarkingsOf = { message: ['The original message was received at '] }.freeze

      # Parse bounce messages from Unknown MTA #1
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['subject'].start_with?('Returned Mail: ')
        return nil unless mhead['from'].start_with?('"Mail Deliver System" ')

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        datestring = ''     # (String) Date string
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(MarkingsOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # The original message was received at Thu, 29 Apr 2010 23:34:45 +0900 (JST)
          # from shironeko@example.jp
          #
          # ---The following addresses had delivery errors---
          #
          # kijitora@example.co.jp [User unknown]
          v = dscontents[-1]

          if Sisimai::String.aligned(e, ['@', ' [', ']'])
            # kijitora@example.co.jp [User unknown]
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            p1 = e.index(' ')
            p2 = e.index(']')
            v['recipient'] = e[0, p1]
            v['diagnosis'] = e[p1 + 2, p2 - p1 - 2]
            recipients += 1

          elsif e.start_with?(MarkingsOf[:message][0])
            # The original message was received at Thu, 29 Apr 2010 23:34:45 +0900 (JST)
            datestring = e[MarkingsOf[:message][0].size, e.size]
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['date']      = datestring || ''
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Unknown MTA #1'; end
    end
  end
end

