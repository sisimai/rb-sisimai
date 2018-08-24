module Sisimai::Bite::Email
  # Sisimai::Bite::Email::IMailServer parses a bounce email which created by
  # Ipswitch IMail Server.
  # Methods in the module are called from only Sisimai::Message.
  module IMailServer
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite::Email/IMailServer.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: [''],  # Blank line
        rfc822:  ['Original message follows.'],
        error:   ['Body of message generated response:'],
      }.freeze

      ReSMTP = {
        conn: %r/(?:SMTP connection failed,|Unexpected connection response from server:)/,
        ehlo: %r|Unexpected response to EHLO/HELO:|,
        mail: %r|Server response to MAIL FROM:|,
        rcpt: %r|Additional RCPT TO generated following response:|,
        data: %r|DATA command generated response:|,
      }.freeze
      ReFailures = {
        hostunknown: %r/Unknown host/,
        userunknown: %r/\A(?:Unknown user|Invalid final delivery userid)/,
        mailboxfull: %r/\AUser mailbox exceeds allowed size/,
        securityerr: %r/\ARequested action not taken: virus detected/,
        undefined:   %r/\Aundeliverable to /,
        expired:     %r/\ADelivery failed \d+ attempts/,
      }.freeze

      def description; return 'IPSWITCH IMail Server'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return ['X-Mailer']; end

      # Parse bounce messages from IMailServer
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
        match  = 0
        match += 1 if mhead['subject'] =~ /\AUndeliverable Mail[ ]*\z/
        match += 1 if mhead['x-mailer'].to_s.start_with?('<SMTP32 v')
        return nil unless match > 0

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
            break if readcursor & Indicators[:'message-rfc822'] > 0

            # Unknown user: kijitora@example.com
            #
            # Original message follows.
            v = dscontents[-1]

            if cv = e.match(/\A([^ ]+)[ ](.+)[:][ \t]*([^ ]+[@][^ ]+)/)
              # Unknown user: kijitora@example.com
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['diagnosis'] = cv[1] + ' ' + cv[2]
              v['recipient'] = cv[3]
              recipients += 1

            elsif cv = e.match(/\Aundeliverable[ ]+to[ ]+(.+)\z/)
              # undeliverable to kijitora@example.com
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              recipients += 1
            else
              # Other error message text
              v['alterrors'] << ' ' << e if v['alterrors']
              v['alterrors'] = e if e.include?(StartingOf[:error][0])
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent'] = self.smtpagent

          unless e['alterrors'].to_s.empty?
            # Copy alternative error message
            e['diagnosis'] = if e['diagnosis']
                               e['alterrors'] + ' ' + e['diagnosis']
                             else
                               e['alterrors']
                             end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
            e.delete('alterrors')
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          ReSMTP.each_key do |r|
            # Detect SMTP command from the message
            next unless e['diagnosis'] =~ ReSMTP[r]
            e['command'] = r.to_s.upcase
            break
          end

          ReFailures.each_key do |r|
            # Verify each regular expression of session errors
            next unless e['diagnosis'] =~ ReFailures[r]
            e['reason'] = r.to_s
            break
          end
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

