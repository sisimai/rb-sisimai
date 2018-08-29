module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Facebook parses a bounce email which created by Facebook.
  # Methods in the module are called from only Sisimai::Message.
  module Facebook
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Facebook.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['This message was created automatically by Facebook.'],
        rfc822:  ['Content-Disposition: inline'],
      }.freeze
      ReFailures = {
        # http://postmaster.facebook.com/response_codes
        # NOT TESTD EXCEPT RCP-P2
        userunknown: [
          'RCP-P1', # The attempted recipient address does not exist.
          'INT-P1', # The attempted recipient address does not exist.
          'INT-P3', # The attempted recpient group address does not exist.
          'INT-P4', # The attempted recipient address does not exist.
        ],
        filtered: [
          'RCP-P2', # The attempted recipient's preferences prevent messages from being delivered.
          'RCP-P3', # The attempted recipient's privacy settings blocked the delivery.
        ],
        mesgtoobig: [
          'MSG-P1', # The message exceeds Facebook's maximum allowed size.
          'INT-P2', # The message exceeds Facebook's maximum allowed size.
        ],
        contenterror: [
          'MSG-P2', # The message contains an attachment type that Facebook does not accept.
          'MSG-P3', # The message contains multiple instances of a header field that can only be present once. Please see RFC 5322, section 3.6 for more information
          'POL-P6', # The message contains a url that has been blocked by Facebook.
          'POL-P7', # The message does not comply with Facebook's abuse policies and will not be accepted.
        ],
        securityerror: [
          'POL-P1', # Your mail server's IP Address is listed on the Spamhaus PBL.
          'POL-P2', # Facebook will no longer accept mail from your mail server's IP Address.
          'POL-P5', # The message contains a virus.
          'POL-P7', # The message does not comply with Facebook's Domain Authentication requirements.
        ],
        notaccept: [
          'POL-P3', # Facebook is not accepting messages from your mail server. This will persist for 4 to 8 hours.
          'POL-P4', # Facebook is not accepting messages from your mail server. This will persist for 24 to 48 hours.
          'POL-T1', # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 1 to 2 hours.
          'POL-T2', # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 4 to 8 hours.
          'POL-T3', # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 24 to 48 hours.
        ],
        rejected: [
          'DNS-P1', # Your SMTP MAIL FROM domain does not exist.
          'DNS-P2', # Your SMTP MAIL FROM domain does not have an MX record.
          'DNS-T1', # Your SMTP MAIL FROM domain exists but does not currently resolve.
          'DNS-P3', # Your mail server does not have a reverse DNS record.
          'DNS-T2', # You mail server's reverse DNS record does not currently resolve.
        ],
        systemerror: [
          'CON-T1', # Facebook's mail server currently has too many connections open to allow another one.
        ],
        toomanyconn: [
          'CON-T3', # Your mail server has opened too many new connections to Facebook's mail servers in a short period of time.
        ],
        suspend: [
          'RCP-T4', # The attempted recipient address is currently deactivated. The user may or may not reactivate it.
        ],
        undefined: [
          'RCP-T1', # The attempted recipient address is not currently available due to an internal system issue. This is a temporary condition.
          'MSG-T1', # The number of recipients on the message exceeds Facebook's allowed maximum.
          'CON-T2', # Your mail server currently has too many connections open to Facebook's mail servers.
          'CON-T4', # Your mail server has exceeded the maximum number of recipients for its current connection.
        ],
      }.freeze

      def description; return 'Facebook: https://www.facebook.com'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Facebook
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
        return nil unless mhead['from'] == 'Facebook <mailer-daemon@mx.facebook.com>'
        return nil unless mhead['subject'] == 'Sorry, your message could not be delivered'

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        fbresponse = ''     # (String) Response code from Facebook
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

            if connvalues == connheader.keys.size
              # Reporting-MTA: dns; 10.138.205.200
              # Arrival-Date: Thu, 23 Jun 2011 02:29:43 -0700
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

              elsif cv = e.match(/\AX-Actual-Recipient:[ ]*(?:RFC|rfc)822;[ ]*(.+)\z/)
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

              elsif cv = e.match(/\ALast-Attempt-Date:[ ]*(.+)\z/)
                # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
                v['date'] = cv[1]
              else
                if cv = e.match(/\ADiagnostic-Code:[ ]*(.+?);[ ]*(.+)\z/)
                  # Diagnostic-Code: smtp; 550 5.1.1 RCP-P2
                  #     http://postmaster.facebook.com/response_codes?ip=192.0.2.135#rcp Refused due to recipient preferences
                  v['spec'] = cv[1].upcase
                  v['diagnosis'] = cv[2]

                elsif p.start_with?('Diagnostic-Code:') && cv = e.match(/\A[ \t]+(.+)\z/)
                  # Continued line of the value of Diagnostic-Code header
                  v['diagnosis'] << ' ' << cv[1]
                  havepassed[-1] = 'Diagnostic-Code: ' << e
                end
              end
            else
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
              end

            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['lhost']   ||= connheader['lhost']
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          if cv = e['diagnosis'].match(/\b([A-Z]{3})[-]([A-Z])(\d)\b/)
            # Diagnostic-Code: smtp; 550 5.1.1 RCP-P2
            lhs = cv[1]
            rhs = cv[2]
            num = cv[3]

            fbresponse = sprintf('%s-%s%d', lhs, rhs, num)
          end

          catch :SESSION do
            ReFailures.each_key do |r|
              # Verify each regular expression of session errors
              ReFailures[r].each do |rr|
                # Check each regular expression
                next unless fbresponse == rr
                e['reason'] = r.to_s
                throw :SESSION
              end
            end
          end

          # http://postmaster.facebook.com/response_codes
          #   Facebook System Resource Issues
          #   These codes indicate a temporary issue internal to Facebook's
          #   system. Administrators observing these issues are not required to
          #   take any action to correct them.
          next if e['reason']

          # * INT-Tx
          #
          # https://groups.google.com/forum/#!topic/cdmix/eXfi4ddgYLQ
          # This block has not been tested because we have no email sample
          # including "INT-T?" error code.
          next unless fbresponse =~ /\AINT-T\d+\z/
          e['reason'] = 'systemerror'
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

