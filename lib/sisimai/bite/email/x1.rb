module Sisimai::Bite::Email
  # Sisimai::Bite::Email::X1 parses a bounce email which created by Unknown
  # MTA #1. Methods in the module are called from only Sisimai::Message.
  module X1
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/X1.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      MarkingsOf = {
        message: %r/\AThe original message was received at (.+)\z/,
        rfc822:  %r/\AReceived: from \d+[.]\d+[.]\d+[.]\d/,
      }.freeze

      def description; return 'Unknown MTA #1'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Unknown MTA #1
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
        return nil unless mhead['subject'].start_with?('Returned Mail: ')
        return nil unless mhead['from'].start_with?('"Mail Deliver System" ')

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        datestring = ''     # (String) Date string
        v = nil

        while e = hasdivided.shift do
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e =~ MarkingsOf[:message]
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e =~ MarkingsOf[:rfc822]
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

            # The original message was received at Thu, 29 Apr 2010 23:34:45 +0900 (JST)
            # from shironeko@example.jp
            #
            # ---The following addresses had delivery errors---
            #
            # kijitora@example.co.jp [User unknown]
            v = dscontents[-1]

            if cv = e.match(/\A([^ ]+?[@][^ ]+?)[ ]+\[(.+)\]\z/)
              # kijitora@example.co.jp [User unknown]
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              v['diagnosis'] = cv[2]
              recipients += 1

            elsif cv = e.match(MarkingsOf[:message])
              # The original message was received at Thu, 29 Apr 2010 23:34:45 +0900 (JST)
              datestring = cv[1]
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['date']      = datestring || ''
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

