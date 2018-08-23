module Sisimai::Bite::Email
  # Sisimai::Bite::Email::SurfControl parses a bounce email which created by
  # WebSense SurfControl.
  # Methods in the module are called from only Sisimai::Message.
  module SurfControl
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/SurfControl.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['Your message could not be sent.'],
        rfc822:  ['Content-Type: message/rfc822'],
      }.freeze

      def description; return 'WebSense SurfControl'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      # X-SEF-ZeroHour-RefID: fgs=000000000
      # X-SEF-Processed: 0_0_0_000__2010_04_29_23_34_45
      # X-Mailer: SurfControl E-mail Filter
      def headerlist;  return ['X-SEF-Processed', 'X-Mailer']; end

      # Parse bounce messages from SurfControl
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
        # :'from' => %r/ [(]Mail Delivery System[)]\z/,
        return nil unless mhead['x-sef-processed']
        return nil unless mhead['x-mailer']
        return nil unless mhead['x-mailer'] == 'SurfControl E-mail Filter'

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

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

            # Your message could not be sent.
            # A transcript of the attempts to send the message follows.
            # The number of attempts made: 1
            # Addressed To: kijitora@example.com
            #
            # Thu 29 Apr 2010 23:34:45 +0900
            # Failed to send to identified host,
            # kijitora@example.com: [192.0.2.5], 550 kijitora@example.com... No such user
            # --- Message non-deliverable.
            v = dscontents[-1]

            if cv = e.match(/\AAddressed To:[ ]*([^ ]+?[@][^ ]+?)\z/)
              # Addressed To: kijitora@example.com
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              recipients += 1

            elsif e =~ /\A(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)[ ,]/
              # Thu 29 Apr 2010 23:34:45 +0900
              v['date'] = e

            elsif cv = e.match(/\A[^ ]+[@][^ ]+:[ ]*\[(\d+[.]\d+[.]\d+[.]\d)\],[ ]*(.+)\z/)
              # kijitora@example.com: [192.0.2.5], 550 kijitora@example.com... No such user
              v['rhost'] = cv[1]
              v['diagnosis'] = cv[2]
            else
              # Fallback, parse RFC3464 headers.
              if cv = e.match(/\ADiagnostic-Code:[ ]*(.+?);[ ]*(.+)\z/)
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                v['spec'] = cv[1].upcase
                v['diagnosis'] = cv[2]

              elsif p.start_with?('Diagnostic-Code:') && cv = e.match(/\A[ ]+(.+)\z/)
                # Continued line of the value of Diagnostic-Code header
                v['diagnosis'] << ' ' << cv[1]
                havepassed[-1] = 'Diagnostic-Code: ' << e

              elsif cv = e.match(/\AAction:[ ]*(.+)\z/)
                # Action: failed
                v['action'] = cv[1].downcase

              elsif cv = e.match(/\AStatus:[ ]*(\d[.]\d+[.]\d+)/)
                # Status: 5.0.-
                v['status'] = cv[1]
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

