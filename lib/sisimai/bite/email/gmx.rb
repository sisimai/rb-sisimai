module Sisimai::Bite::Email
  # Sisimai::Bite::Email::GMX parses a bounce email which created by GMX.
  # Methods in the module are called from only Sisimai::Message.
  module GMX
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/GMX.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['This message was created automatically by mail delivery software'],
        rfc822:  ['--- The header of the original message is following'],
      }.freeze
      MessagesOf = { expired: ['delivery retry timeout exceeded'] }.freeze

      def description; return 'GMX: http://www.gmx.net'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end

      # Envelope-To: <kijitora@mail.example.com>
      # X-GMX-Antispam: 0 (Mail was not recognized as spam); Detail=V3;
      # X-GMX-Antivirus: 0 (no virus found)
      # X-UI-Out-Filterresults: unknown:0;
      def headerlist;  return ['X-GMX-Antispam']; end

      # Parse bounce messages from GMX
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
        # :from    => %r/\AMAILER-DAEMON[@]/,
        # :subject => %r/\AMail delivery failed: returning message to sender\z/,
        return nil unless mhead['x-gmx-antispam']

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
            if e.start_with?(StartingOf[:rfc822][0])
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
            #
            # A message that you sent could not be delivered to one or more of
            # its recipients. This is a permanent error. The following address
            # failed:
            #
            # "shironeko@example.jp":
            # SMTP error from remote server after RCPT command:
            # host: mx.example.jp
            # 5.1.1 <shironeko@example.jp>... User Unknown
            v = dscontents[-1]

            if cv = e.match(/\A["]([^ ]+[@][^ ]+)["]:\z/) || e.match(/\A[<]([^ ]+[@][^ ]+)[>]\z/)
              # "shironeko@example.jp":
              # ---- OR ----
              # <kijitora@6jo.example.co.jp>
              #
              # Reason:
              # delivery retry timeout exceeded
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              recipients += 1

            elsif cv = e.match(/\ASMTP error .+ ([A-Z]{4}) command:\z/)
              # SMTP error from remote server after RCPT command:
              v['command'] = cv[1]

            elsif cv = e.match(/\Ahost:[ \t]*(.+)\z/)
              # host: mx.example.jp
              v['rhost'] = cv[1]
            else
              # Get error message
              if e =~ /\b[45][.]\d[.]\d\b/ || e =~ /[<][^ ]+[@][^ ]+[>]/ || e =~ /\b[45]\d{2}\b/
                v['diagnosis'] ||= e
              else
                next if e.empty?
                if e.start_with?('Reason:')
                  # Reason:
                  # delivery retry timeout exceeded
                  v['diagnosis'] = e

                elsif v['diagnosis'] == 'Reason:'
                  v['diagnosis'] = e
                end
              end
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

