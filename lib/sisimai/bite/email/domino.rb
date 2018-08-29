module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Domino parses a bounce email which created by IBM
  # Domino Server. Methods in the module are called from only Sisimai::Message.
  module Domino
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Domino.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['Your message'],
        rfc822:  ['Content-Type: message/delivery-status'],
      }.freeze
      MessagesOf = {
        userunknown: [
          'not listed in Domino Directory',
          'not listed in public Name & Address Book',
          'Domino ディレクトリには見つかりません',
        ],
        filtered:    ['Cannot route mail to user'],
        systemerror: ['Several matches found in Domino Directory'],
      }.freeze

      def description; return 'IBM Domino Server'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from IBM Domino Server
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
        return nil unless mhead['subject'].start_with?('DELIVERY FAILURE:')

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        subjecttxt = ''     # (String) The value of Subject:
        v = nil

        while e = hasdivided.shift do
          next if e.empty?

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e.start_with?(StartingOf[:message][0])
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

            # Your message
            #
            #   Subject: Test Bounce
            #
            # was not delivered to:
            #
            #   kijitora@example.net
            #
            # because:
            #
            #   User some.name (kijitora@example.net) not listed in Domino Directory
            #
            v = dscontents[-1]

            if e.start_with?('was not delivered to:')
              # was not delivered to:
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] ||= e
              recipients += 1

            elsif cv = e.match(/\A[ ][ ]([^ ]+[@][^ ]+)\z/)
              # Continued from the line "was not delivered to:"
              #   kijitora@example.net
              v['recipient'] = Sisimai::Address.s3s4(cv[1])

            elsif e.start_with?('because:')
              # because:
              v['diagnosis'] = e
            else
              if v['diagnosis'].to_s == 'because:'
                # Error message, continued from the line "because:"
                v['diagnosis'] = e

              elsif cv = e.match(/\A[ ][ ]Subject: (.+)\z/)
                #   Subject: Nyaa
                subjecttxt = cv[1]
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['recipient'] = Sisimai::Address.s3s4(e['recipient'])

          MessagesOf.each_key do |r|
            # Check each regular expression of Domino error messages
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r.to_s
            pseudostatus = Sisimai::SMTP::Status.code(r.to_s, false)
            e['status'] = pseudostatus unless pseudostatus.empty?
            break
          end
          e.each_key { |a| e[a] ||= '' }
        end

        unless rfc822list.any? { |a| a.start_with?('Subject:') }
          # Set the value of subjecttxt as a Subject if there is no original
          # message in the bounce mail.
          rfc822list << ('Subject: ' << subjecttxt)
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

