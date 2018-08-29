module Sisimai::Bite::Email
  # Sisimai::Bite::Email::McAfee parses a bounce email which created by McAfee
  # Email Appliance. Methods in the module are called from only Sisimai::Message.
  module McAfee
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/McAfee.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['--- The following addresses had delivery problems ---'],
        rfc822:  ['Content-Type: message/rfc822'],
      }.freeze
      ReFailures = {
        userunknown: %r/(?:User [(].+[@].+[)] unknown[.]|550 Unknown user [^ ]+[@][^ ]+)/,
      }.freeze

      def description; return 'McAfee Email Appliance'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return ['X-NAI-Header']; end

      # Parse bounce messages from McAfee Email Appliance
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
        return nil unless mhead['x-nai-header']
        return nil unless mhead['x-nai-header'].start_with?('Modified by McAfee ')
        return nil unless mhead['subject'] == 'Delivery Status'

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        diagnostic = ''     # (String) Alternative diagnostic message
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e.include?(StartingOf[:message][0])
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

            # Content-Type: text/plain; name="deliveryproblems.txt"
            #
            #    --- The following addresses had delivery problems ---
            #
            # <user@example.com>   (User unknown user@example.com)
            #
            # --------------Boundary-00=_00000000000000000000
            # Content-Type: message/delivery-status; name="deliverystatus.txt"
            #
            v = dscontents[-1]

            if cv = e.match(/\A[<]([^ ]+[@][^ ]+)[>][ \t]+[(](.+)[)]\z/)
              # <kijitora@example.co.jp>   (Unknown user kijitora@example.co.jp)
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              diagnostic = cv[2]
              recipients += 1

            elsif cv = e.match(/\AOriginal-Recipient:[ ]*([^ ]+)\z/)
              # Original-Recipient: <kijitora@example.co.jp>
              v['alias'] = Sisimai::Address.s3s4(cv[1])

            elsif cv = e.match(/\AAction:[ ]*(.+)\z/)
              # Action: failed
              v['action'] = cv[1].downcase

            elsif cv = e.match(/\ARemote-MTA:[ ]*(.+)\z/)
              # Remote-MTA: 192.0.2.192
              v['rhost'] = cv[1].downcase
            else
              if cv = e.match(/\ADiagnostic-Code:[ ]*(.+?);[ ]*(.+)\z/)
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                v['spec'] = cv[1].upcase
                v['diagnosis'] = cv[2]

              elsif p.start_with?('Diagnostic-Code:') && cv = e.match(/\A[ \t]+(.+)\z/)
                # Continued line of the value of Diagnostic-Code header
                v['diagnosis'] << ' ' << cv[1]
                havepassed[-1] = 'Diagnostic-Code: ' << e
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'] || diagnostic)

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

