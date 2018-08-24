module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Bigfoot parses a bounce email which created by Bigfoot.
  # Methods in the module are called from only Sisimai::Message.
  module Bigfoot
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Bigfoot.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = { rfc822: ['Content-Type: message/partial'] }.freeze
      MarkingsOf = { message: %r/\A[ \t]+[-]+[ \t]*Transcript of session follows/ }.freeze

      def description; return 'Bigfoot: http://www.bigfoot.com'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Bigfoot
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
        # :subject  => %r/\AReturned mail: /,
        match  = 0
        match += 1 if mhead['from'].include?('@bigfoot.com>')
        match += 1 if mhead['received'].any? { |a| a.include?('.bigfoot.com') }
        return nil unless match > 0

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        commandtxt = ''     # (String) SMTP Command name begin with the string '>>>'
        esmtpreply = ''     # (String) Reply from remote server on SMTP session
        connvalues = 0      # (Integer) Flag, 1 if all the value of connheader have been set
        connheader = {
          'date'  => '',    # The value of Arrival-Date header
          'lhost' => '',    # The value of Reporting-MTA header
        }
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e =~ MarkingsOf[:message]
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

            if connvalues == connheader.keys.size
              # Final-Recipient: RFC822; <destinaion@example.net>
              # Action: failed
              # Status: 5.7.1
              # Remote-MTA: DNS; p01c11m075.mx.example.net
              # Diagnostic-Code: SMTP; 553 Invalid recipient destinaion@example.net (Mode: normal)
              # Last-Attempt-Date: Sun, 28 Dec 2014 18:17:16 -0800
              v = dscontents[-1]

              if cv = e.match(/\AFinal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # Final-Recipient: RFC822; <destinaion@example.net>
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Bite.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = Sisimai::Address.s3s4(cv[1])
                recipients += 1

              elsif cv = e.match(/\AAction:[ ]*(.+)\z/)
                # Action: failed
                v['action'] = cv[1].downcase

              elsif cv = e.match(/\AStatus:[ ]*(\d[.]\d+[.]\d+)/)
                # Status: 5.7.1
                v['status'] = cv[1]

              elsif cv = e.match(/\ARemote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Remote-MTA: DNS; p01c11m075.mx.example.net
                v['rhost'] = cv[1].downcase
              else
                # Get error message
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
            else
              #    ----- Transcript of session follows -----
              # >>> RCPT TO:<destinaion@example.net>
              # <<< 553 Invalid recipient destinaion@example.net (Mode: normal)
              #
              # --201412281816847
              # Content-Type: message/delivery-status
              #
              # Reporting-MTA: dns; litemail57.bigfoot.com
              # Arrival-Date: Sun, 28 Dec 2014 18:17:16 -0800
              #
              if cv = e.match(/\AReporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Reporting-MTA: dns; mx.example.jp
                next unless connheader['lhost'].empty?
                connheader['lhost'] = cv[1].downcase
                connvalues += 1

              elsif cv = e.match(/\AArrival-Date:[ ]*(.+)\z/)
                # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                next unless connheader['date'].empty?
                connheader['date'] = cv[1]
                connvalues += 1
              else
                #    ----- Transcript of session follows -----
                # >>> RCPT TO:<destinaion@example.net>
                # <<< 553 Invalid recipient destinaion@example.net (Mode: normal)
                if cv = e.match(/\A[>]{3}[ ]+([A-Z]{4})[ ]?/)
                  # >>> DATA
                  commandtxt = cv[1]

                elsif cv = e.match(/\A[<]{3}[ ]+(.+)\z/)
                  # <<< Response
                  esmtpreply = cv[1]
                end

              end

            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          connheader.each_key { |a| e[a] ||= connheader[a] || '' }

          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['command']   = commandtxt
          if e['command'].empty?
            e['command'] = 'EHLO' unless esmtpreply.empty?
          end
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

