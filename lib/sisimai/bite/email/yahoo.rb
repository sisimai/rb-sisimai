module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Yahoo parses a bounce email which created by Yahoo!
  # MAIL. Methods in the module are called from only Sisimai::Message.
  module Yahoo
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Yahoo.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['Sorry, we were unable to deliver your message'],
        rfc822:  ['--- Below this line is a copy of the message.'],
      }.freeze

      def description; return 'Yahoo! MAIL: https://www.yahoo.com'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end

      # X-YMailISG: YtyUVyYWLDsbDh...
      # X-YMail-JAS: Pb65aU4VM1mei...
      # X-YMail-OSG: bTIbpDEVM1lHz...
      # X-Originating-IP: [192.0.2.9]
      def headerlist;  return ['X-YMailISG']; end

      # Parse bounce messages from Yahoo! MAIL
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
        # :subject => %r/\AFailure Notice\z/,
        return nil unless mhead['x-ymailisg']

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
            next if e.empty?

            # Sorry, we were unable to deliver your message to the following address.
            #
            # <kijitora@example.org>:
            # Remote host said: 550 5.1.1 <kijitora@example.org>... User Unknown [RCPT_TO]
            v = dscontents[-1]

            if cv = e.match(/\A[<](.+[@].+)[>]:[ \t]*\z/)
              # <kijitora@example.org>:
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              v['diagnosis'] = ''
              recipients += 1
            else
              if e.start_with?('Remote host said:')
                # Remote host said: 550 5.1.1 <kijitora@example.org>... User Unknown [RCPT_TO]
                v['diagnosis'] = e

                # Get SMTP command from the value of "Remote host said:"
                if cv = e.match(/\[([A-Z]{4}).*\]\z/) then v['command'] = cv[1] end
              else
                # <mailboxfull@example.jp>:
                # Remote host said:
                # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
                # [RCPT_TO]
                if v['diagnosis'].start_with?('Remote host said:')
                  # Remote host said:
                  # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
                  if cv = e.match(/\[([A-Z]{4}).*\]\z/)
                    # [RCPT_TO]
                    v['command'] = cv[1]
                  else
                    # 550 5.2.2 <mailboxfull@example.jp>... Mailbox Full
                    v['diagnosis'] = e
                  end
                else
                  # Error message which does not start with 'Remote host said:'
                  v['diagnosis'] << ' ' << e
                end
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].gsub(/\\n/, ' '))
          e['agent']     = self.smtpagent
          e['command'] ||= 'RCPT' if e['diagnosis'] =~ /[<].+[@].+[>]/
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

