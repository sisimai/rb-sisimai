module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Zoho parses a bounce email which created by Zoho Mail.
  # Methods in the module are called from only Sisimai::Message.
  module Zoho
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Zoho.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['This message was created automatically by mail delivery'],
        rfc822:  ['from mail.zoho.com by mx.zohomail.com'],
      }.freeze
      MessagesOf = { expired: ['Host not reachable'] }.freeze

      def description; return 'Zoho Mail: https://www.zoho.com'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end

      # X-ZohoMail: Si CHF_MF_NL SS_10 UW48 UB48 FMWL UW48 UB48 SGR3_1_09124_42
      # X-Zoho-Virus-Status: 2
      # X-Mailer: Zoho Mail
      def headerlist;  return ['X-ZohoMail']; end

      # Parse bounce messages from Zoho Mail
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
        # :'from'     => %r/mailer-daemon[@]mail[.]zoho[.]com\z/,
        # :'subject'  => %r{\A(?:
        #      Undelivered[ ]Mail[ ]Returned[ ]to[ ]Sender
        #     |Mail[ ]Delivery[ ]Status[ ]Notification
        #     )
        # }x,
        # :'x-mailer' => %r/\AZoho Mail\z/,
        return nil unless mhead['x-zohomail']

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        qprintable = false
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
            if e.include?(StartingOf[:rfc822][0])
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

            # This message was created automatically by mail delivery software.
            # A message that you sent could not be delivered to one or more of its recip=
            # ients. This is a permanent error.=20
            #
            # kijitora@example.co.jp Invalid Address, ERROR_CODE :550, ERROR_CODE :5.1.=
            # 1 <kijitora@example.co.jp>... User Unknown

            # This message was created automatically by mail delivery software.
            # A message that you sent could not be delivered to one or more of its recipients. This is a permanent error.
            #
            # shironeko@example.org Invalid Address, ERROR_CODE :550, ERROR_CODE :Requested action not taken: mailbox unavailable
            v = dscontents[-1]

            if cv = e.match(/\A([^ ]+[@][^ ]+)[ \t]+(.+)\z/)
              # kijitora@example.co.jp Invalid Address, ERROR_CODE :550, ERROR_CODE :5.1.=
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              v['diagnosis'] = cv[2]

              if v['diagnosis'].end_with?('=')
                # Quoted printable
                v['diagnosis'] = v['diagnosis'].chomp('=')
                qprintable = true
              end
              recipients += 1

            elsif cv = e.match(/\A\[Status: .+[<]([^ ]+[@][^ ]+)[>],/)
              # Expired
              # [Status: Error, Address: <kijitora@6kaku.example.co.jp>, ResponseCode 421, , Host not reachable.]
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              v['diagnosis'] = e
              recipients += 1
            else
              # Continued line
              next unless qprintable
              v['diagnosis'] << e
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].gsub(/\\n/, ' '))

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

