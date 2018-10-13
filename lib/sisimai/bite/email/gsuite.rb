module Sisimai::Bite::Email
  # Sisimai::Bite::Email::GSuite parses a bounce email which created by G Suite.
  # Methods in the module are called from only Sisimai::Message.
  module GSuite
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/GSuite.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      MarkingsOf = {
        message: %r/\A[*][*][ ].+[ ][*][*]\z/,
        rfc822:  %r{\AContent-Type:[ ]*(?:message/rfc822|text/rfc822-headers)\z},
        error:   %r/\AThe[ ]response([ ]from[ ]the[ ]remote[ ]server)?[ ]was:\z/,
        html:    %r{\AContent-Type:[ ]*text/html;[ ]*charset=['"]?(?:UTF|utf)[-]8['"]?\z},
      }.freeze
      MessagesOf = {
        userunknown:  ["because the address couldn't be found. Check for typos or unnecessary spaces and try again."],
        notaccept:    ['Null MX'],
        networkerror: [' responded with code NXDOMAIN'],
      }.freeze

      def description; return 'G Suite: https://gsuite.google.com'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return ['X-Gm-Message-State']; end

      # Parse bounce messages from G Suite (Transfer from G Suite to a destinaion host)
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
        return nil unless mhead['from'].end_with?('<mailer-daemon@googlemail.com>')
        return nil unless mhead['subject'].start_with?('Delivery Status Notification')
        return nil unless mhead['x-gm-message-state']

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        endoferror = false  # (Integer) Flag for a blank line after error messages
        anotherset = {}     # (Hash) Another error information
        emptylines = 0      # (Integer) The number of empty lines
        connvalues = 0      # (Integer) Flag, 1 if all the value of connheader have been set
        connheader = {
          'date'  => '',    # The value of Arrival-Date header
          'lhost' => '',    # The value of Reporting-MTA header
        }
        v = nil

        while e = hasdivided.shift do
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e =~ MarkingsOf[:message]
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e =~ MarkingsOf[:rfc822]
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

            if connvalues == connheader.keys.size
              # Final-Recipient: rfc822; kijitora@example.de
              # Action: failed
              # Status: 5.0.0
              # Remote-MTA: dns; 192.0.2.222 (192.0.2.222, the server for the domain.)
              # Diagnostic-Code: smtp; 550 #5.1.0 Address rejected.
              # Last-Attempt-Date: Fri, 24 Mar 2017 23:34:10 -0700 (PDT)
              v = dscontents[-1]

              if cv = e.match(/\AFinal-Recipient:[ ]*(?:RFC|rfc)822;[ ]*(.+)\z/)
                # Final-Recipient: rfc822; kijitora@example.de
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Bite.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              elsif cv = e.match(/\AAction:[ ]*(.+)\z/)
                # Action: failed
                v['action'] = cv[1].downcase

              elsif cv = e.match(/\AStatus:[ ]*(\d[.]\d+[.]\d+)/)
                # Status: 5.0.0
                v['status'] = cv[1]

              elsif cv = e.match(/\ARemote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Remote-MTA: dns; 192.0.2.222 (192.0.2.222, the server for the domain.)
                v['rhost'] = cv[1].downcase
                v['rhost'] = '' if v['rhost'] =~ /\A\s+\z/  # Remote-MTA: DNS;

              elsif cv = e.match(/\ALast-Attempt-Date:[ ]*(.+)\z/)
                # Last-Attempt-Date: Fri, 24 Mar 2017 23:34:10 -0700 (PDT)
                v['date'] = cv[1]
              else
                if cv = e.match(/\ADiagnostic-Code:[ ]*(.+?);[ ]*(.+)\z/)
                  # Diagnostic-Code: smtp; 550 #5.1.0 Address rejected.
                  v['spec'] = cv[1].upcase
                  v['diagnosis'] = cv[2]
                else
                  # Append error messages continued from the previous line
                  if endoferror == false && !v['diagnosis'].to_s.empty?
                    endoferror ||= true if e.empty?
                    endoferror ||= true if e.start_with?('--')

                    next if endoferror
                    next unless e.start_with?(' ')
                    v['diagnosis'] << e
                  end
                end
              end
            else
              # Reporting-MTA: dns; googlemail.com
              # Received-From-MTA: dns; sironeko@example.jp
              # Arrival-Date: Fri, 24 Mar 2017 23:34:07 -0700 (PDT)
              # X-Original-Message-ID: <06C1ED5C-7E02-4036-AEE1-AA448067FB2C@example.jp>
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
                # Detect SMTP session error or connection error
                if e =~ MarkingsOf[:error]
                  # The response from the remote server was:
                  anotherset['diagnosis'] << e
                else
                  # ** Address not found **
                  #
                  # Your message wasn't delivered to * because the address couldn't be found.
                  # Check for typos or unnecessary spaces and try again.
                  #
                  # The response from the remote server was:
                  # 550 #5.1.0 Address rejected.
                  next if e =~ MarkingsOf[:html]

                  if anotherset['diagnosis']
                    # Continued error messages from the previous line like
                    # "550 #5.1.0 Address rejected."
                    next if e =~ /\AContent-Type:/
                    next if emptylines > 5
                    if e.empty?
                      # Count and next()
                      emptylines += 1
                      next
                    end
                    anotherset['diagnosis'] << ' ' << e
                  else
                    # ** Address not found **
                    #
                    # Your message wasn't delivered to * because the address couldn't be found.
                    # Check for typos or unnecessary spaces and try again.
                    next if e.empty?
                    next unless e =~ MarkingsOf[:message]
                    anotherset['diagnosis'] = e
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

          if anotherset['diagnosis']
            # Copy alternative error message
            e['diagnosis'] = anotherset['diagnosis'] unless e['diagnosis']

            if e['diagnosis'] =~ /\A\d+\z/
              e['diagnosis'] = anotherset['diagnosis']
            else
              # More detailed error message is in "anotherset"
              as = nil  # status
              ar = nil  # replycode

              e['status']    ||= ''
              e['replycode'] ||= ''

              if e['status'] == '' || e['status'].start_with?('4.0.0', '5.0.0')
                # Check the value of D.S.N. in anotherset
                as = Sisimai::SMTP::Status.find(anotherset['diagnosis'])
                if !as.empty? && as[-3, 3] != '0.0'
                  # The D.S.N. is neither an empty nor *.0.0
                  e['status'] = as
                end
              end

              if e['replycode'].empty? || e['replycode'].start_with?('400', '500')
                # Check the value of SMTP reply code in anotherset
                ar = Sisimai::SMTP::Reply.find(anotherset['diagnosis'])
                if !ar.empty? && ar[-2, 2].to_i != 0
                  # The SMTP reply code is neither an empty nor *00
                  e['replycode'] = ar
                end
              end

              if (as || ar) && (anotherset['diagnosis'].size > e['diagnosis'].size)
                # Update the error message in e['diagnosis']
                e['diagnosis'] = anotherset['diagnosis']
              end
            end
          end

          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['agent']     = self.smtpagent

          MessagesOf.each_key do |r|
            # Guess an reason of the bounce
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

