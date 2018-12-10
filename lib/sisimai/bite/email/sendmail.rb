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

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

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
        anotherset = {}     # Another error information
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            if e.start_with?(StartingOf[:message][0])
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part(message/rfc822)
            if e.start_with?(StartingOf[:rfc822][0], StartingOf[:rfc822][1])
              readcursor |= Indicators[:'message-rfc822']
              next
            end
          end

          if readcursor & Indicators[:'message-rfc822'] > 0
            # message/rfc822 OR text/rfc822-headers part
            if e.empty?
              blanklines += 1
              break if blanklines > 1
              next
            end
            rfc822list << e
          else
            # message/delivery-status part
            next if (readcursor & Indicators[:deliverystatus]) == 0
            next if e.empty?

            if f = Sisimai::RFC1894.match(e)
              # "e" matched with any field defined in RFC3464
              o = Sisimai::RFC1894.field(e) || next
              v = dscontents[-1]

              if o[-1] == 'addr'
                # Final-Recipient: rfc822; kijitora@example.jp
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                if o[0] == 'final-recipient'
                  # Final-Recipient: rfc822; kijitora@example.jp
                  if v['recipient']
                    # There are multiple recipient addresses in the message body.
                    dscontents << Sisimai::Bite.DELIVERYSTATUS
                    v = dscontents[-1]
                  end
                  v['recipient'] = o[2]
                  recipients += 1
                else
                  # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                  v['alias'] = o[2]
                end
              elsif o[-1] == 'code'
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                v['spec'] = o[1]
                v['diagnosis'] = o[2]
              else
                # Other DSN fields defined in RFC3464
                next unless fieldtable.key?(o[0].to_sym)
                v[fieldtable[o[0].to_sym]] = o[2]

                next unless f == 1
                permessage[fieldtable[o[0].to_sym]] = o[2]
              end
            else
              # The line does not begin with a DSN field defined in RFC3464
              #
              # ----- Transcript of session follows -----
              # ... while talking to mta.example.org.:
              # >>> DATA
              # <<< 550 Unknown user recipient@example.jp
              # 554 5.0.0 Service unavailable
              # ...
              # Reporting-MTA: dns; mx.example.jp
              # Received-From-MTA: DNS; x1x2x3x4.dhcp.example.ne.jp
              # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
              if e =~ /\A[^ ]/
                if cv = e.match(/\A[>]{3}[ ]+([A-Z]{4})[ ]?/)
                  # >>> DATA
                  commandtxt = cv[1]

                elsif cv = e.match(/\A[<]{3}[ ]+(.+)\z/)
                  # <<< Response
                  esmtpreply = cv[1]
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
              else
                # Continued line of the value of Diagnostic-Code header
                next unless p.start_with?('Diagnostic-Code:')
                next unless cv = e.match(/\A[ \t]+(.+)\z/)
                v['diagnosis'] << ' ' << cv[1]
                havepassed[-1] = 'Diagnostic-Code: ' << e
              end
            end
          end # End of message/delivery-status
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          e['lhost'] ||= permessage['rhost']
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }

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
