module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Sendmail parses a bounce email which created by
  # v8 Sendmail. Methods in the module are called from only Sisimai::Message.
  module Sendmail
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Sendmail.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        # Error text regular expressions which defined in sendmail/savemail.c
        #   savemail.c:1040|if (printheader && !putline("   ----- Transcript of session follows -----\n",
        #   savemail.c:1041|          mci))
        #   savemail.c:1042|  goto writeerr;
        #
        rfc822:  ['Content-Type: message/rfc822', 'Content-Type: text/rfc822-headers'],
        message: ['   ----- Transcript of session follows -----'],
        error:   ['... while talking to '],
      }.freeze

      def description; return 'V8Sendmail: /usr/sbin/sendmail'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Sendmail
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
        return nil unless mhead['subject'] =~ /(?:see transcript for details\z|\AWarning: )/
        unless mhead['subject'].downcase =~ /\A[ \t]*fwd?:/
          # Fwd: Returned mail: see transcript for details
          # Do not execute this code if the bounce mail is a forwarded message.
          return nil unless mhead['from'].start_with?('Mail Delivery Subsystem')
        end

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        commandtxt = ''     # (String) SMTP Command name begin with the string '>>>'
        esmtpreply = ''     # (String) Reply from remote server on SMTP session
        sessionerr = false  # (Boolean) Flag, "true" if it is SMTP session error
        connvalues = 0      # (Integer) Flag, 1 if all the value of connheader have been set
        connheader = {
          'date'  => '',    # The value of Arrival-Date header
          'rhost' => '',    # The value of Reporting-MTA header
        }
        anotherset = {}     # Another error information
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e.start_with?(StartingOf[:message][0])
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e.start_with?(StartingOf[:rfc822][0], StartingOf[:rfc822][1])
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
              # Final-Recipient: RFC822; userunknown@example.jp
              # X-Actual-Recipient: RFC822; kijitora@example.co.jp
              # Action: failed
              # Status: 5.1.1
              # Remote-MTA: DNS; mx.example.jp
              # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
              # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
              v = dscontents[-1]

              if cv = e.match(/\AFinal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # Final-Recipient: RFC822; userunknown@example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Bite.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              elsif cv = e.match(/\AX-Actual-Recipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # X-Actual-Recipient: RFC822; kijitora@example.co.jp
                v['alias'] = cv[1]

              elsif cv = e.match(/\AAction:[ ]*(.+)\z/)
                # Action: failed
                v['action'] = cv[1].downcase

              elsif cv = e.match(/\AStatus:[ ]*(\d[.]\d+[.]\d+)/)
                # Status: 5.1.1
                # Status:5.2.0
                # Status: 5.1.0 (permanent failure)
                v['status'] = cv[1]

              elsif cv = e.match(/\ARemote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Remote-MTA: DNS; mx.example.jp
                v['rhost'] = cv[1].downcase
                v['rhost'] = '' if v['rhost'] =~ /\A\s+\z/  # Remote-MTA: DNS;

              elsif cv = e.match(/\ALast-Attempt-Date:[ ]*(.+)\z/)
                # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
                v['date'] = cv[1]
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
            else
              # ----- Transcript of session follows -----
              # ... while talking to mta.example.org.:
              # >>> DATA
              # <<< 550 Unknown user recipient@example.jp
              # 554 5.0.0 Service unavailable
              # ...
              # Reporting-MTA: dns; mx.example.jp
              # Received-From-MTA: DNS; x1x2x3x4.dhcp.example.ne.jp
              # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
              if cv = e.match(/\A[>]{3}[ ]+([A-Z]{4})[ ]?/)
                # >>> DATA
                commandtxt = cv[1]

              elsif cv = e.match(/\A[<]{3}[ ]+(.+)\z/)
                # <<< Response
                esmtpreply = cv[1]

              elsif cv = e.match(/\AReporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Reporting-MTA: dns; mx.example.jp
                next unless connheader['rhost'].empty?
                connheader['rhost'] = cv[1].downcase
                connvalues += 1

              elsif cv = e.match(/\AReceived-From-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Received-From-MTA: DNS; x1x2x3x4.dhcp.example.ne.jp
                next if connheader['lhost']

                # The value of "lhost" is optional
                connheader['lhost'] = cv[1].downcase
                connvalues += 1

              elsif cv = e.match(/\AArrival-Date:[ ]*(.+)\z/)
                # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                next unless connheader['date'].empty?
                connheader['date'] = cv[1]
                connvalues += 1
              else
                # Detect SMTP session error or connection error
                next if sessionerr
                if e.start_with?(StartingOf[:error][0])
                  # ----- Transcript of session follows -----
                  # ... while talking to mta.example.org.:
                  sessionerr = true
                  next
                end

                if cv = e.match(/\A[<](.+)[>][.]+ (.+)\z/)
                  # <kijitora@example.co.jp>... Deferred: Name server: example.co.jp.: host name lookup failure
                  anotherset['recipient'] = cv[1]
                  anotherset['diagnosis'] = cv[2]
                else
                  # ----- Transcript of session follows -----
                  # Message could not be delivered for too long
                  # Message will be deleted from queue
                  next if e =~ /\A[ \t]*[-]+/
                  if cv = e.match(/\A[45]\d\d[ \t]([45][.]\d[.]\d)[ \t].+/)
                    # 550 5.1.2 <kijitora@example.org>... Message
                    #
                    # DBI connect('dbname=...')
                    # 554 5.3.0 unknown mailer error 255
                    anotherset['status'] = cv[1]
                    anotherset['diagnosis'] ||= ''
                    anotherset['diagnosis'] << ' ' << e

                  elsif e.start_with?('Message ', 'Warning: ')
                    # Message could not be delivered for too long
                    # Warning: message still undelivered after 4 hours
                    anotherset['diagnosis'] ||= ''
                    anotherset['diagnosis'] << ' ' << e
                  end
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
          e['command'] ||= commandtxt
          if e['command'].empty?
            e['command'] = 'EHLO' unless esmtpreply.empty?
          end

          if anotherset['diagnosis']
            # Copy alternative error message
            e['diagnosis'] = anotherset['diagnosis'] if e['diagnosis'] =~ /\A[ \t]+\z/
            e['diagnosis'] = anotherset['diagnosis'] unless e['diagnosis']
            e['diagnosis'] = anotherset['diagnosis'] if e['diagnosis'] =~ /\A\d+\z/
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          if anotherset['status']
            # Check alternative status code
            if e['status'].empty? || e['status'] !~ /\A[45][.]\d[.]\d\z/
              # Override alternative status code
              e['status'] = anotherset['status']
            end
          end

          unless e['recipient'] =~ /\A[^ ]+[@][^ ]+\z/
            # @example.jp, no local part
            if cv = e['diagnosis'].match(/[<]([^ ]+[@][^ ]+)[>]/)
              # Get email address from the value of Diagnostic-Code header
              e['recipient'] = cv[1]
            end
          end
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end
