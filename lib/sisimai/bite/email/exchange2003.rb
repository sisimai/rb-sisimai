module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Exchange2003 parses a bounce email which created by
  # Microsoft Exchange Server 2003.
  # Methods in the module are called from only Sisimai::Message.
  module Exchange2003
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Exchange2003.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['Your message'],
        error:   ['did not reach the following recipient(s):'],
        rfc822:  ['Content-Type: message/rfc822'],
      }.freeze
      ErrorCodes = {
        onhold: [
          '000B099C', # Host Unknown, Message exceeds size limit, ...
          '000B09AA', # Unable to relay for, Message exceeds size limit,...
          '000B09B6', # Error messages by remote MTA
        ],
        userunknown: [
          '000C05A6', # Unknown Recipient,
        ],
        systemerror: [
          '00010256', # Too many recipients.
          '000D06B5', # No proxy for recipient (non-smtp mail?)
        ],
        networkerror: [
          '00120270', # Too Many Hops
        ],
        contenterr: [
          '00050311', # Conversion to Internet format failed
          '000502CC', # Conversion to Internet format failed
        ],
        securityerr: [
          '000B0981', # 502 Server does not support AUTH
        ],
        filtered: [
          '000C0595', # Ambiguous Recipient
        ],
      }.freeze

      def description; return 'Microsoft Exchange Server 2003'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return ['X-MS-Embedded-Report', 'X-MimeOLE']; end

      # Parse bounce messages from Microsoft Exchange Server 2003
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
        match = 0
        tryto = []

        match += 1 if mhead['x-ms-embedded-report']
        catch :EXCHANGE_OR_NOT do
          while true
            throw :EXCHANGE_OR_NOT if match > 0

            if mhead['x-mailer']
              # X-Mailer:  Microsoft Exchange Server Internet Mail Connector Version 4.0.994.63
              # X-Mailer: Internet Mail Service (5.5.2232.9)
              tryto = ['Internet Mail Service (', 'Microsoft Exchange Server Internet Mail Connector']
              match += 1 if mhead['x-mailer'].start_with?(tryto[0], tryto[1])
              throw :EXCHANGE_OR_NOT if match > 0
            end

            if mhead['x-mimeole']
              # X-MimeOLE: Produced By Microsoft Exchange V6.5
              match += 1 if mhead['x-mimeole'].start_with?('Produced By Microsoft Exchange')
              throw :EXCHANGE_OR_NOT if match > 0
            end

            throw :EXCHANGE_OR_NOT if mhead['received'].empty?
            mhead['received'].each do |e|
              # Received: by ***.**.** with Internet Mail Service (5.5.2657.72)
              next unless e.include?(' with Internet Mail Service (')
              match += 1
              throw :EXCHANGE_OR_NOT
            end
            break
          end
        end
        return nil unless match > 0

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        statuspart = false  # (Boolean) Flag, true = have got delivery status part.
        connvalues = 0      # (Integer) Flag, 1 if all the value of connheader have been set
        connheader = {
          'to'      => '',  # The value of "To"
          'date'    => '',  # The value of "Date"
          'subject' => '',  # The value of "Subject"
        }
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
            next if statuspart

            if connvalues == connheader.keys.size
              # did not reach the following recipient(s):
              #
              # kijitora@example.co.jp on Thu, 29 Apr 2007 16:51:51 -0500
              #     The recipient name is not recognized
              #     The MTS-ID of the original message is: c=jp;a= ;p=neko
              # ;l=EXCHANGE000000000000000000
              #     MSEXCH:IMS:KIJITORA CAT:EXAMPLE:EXCHANGE 0 (000C05A6) Unknown Recipient
              # mikeneko@example.co.jp on Thu, 29 Apr 2007 16:51:51 -0500
              #     The recipient name is not recognized
              #     The MTS-ID of the original message is: c=jp;a= ;p=neko
              # ;l=EXCHANGE000000000000000000
              #     MSEXCH:IMS:KIJITORA CAT:EXAMPLE:EXCHANGE 0 (000C05A6) Unknown Recipient
              v = dscontents[-1]

              if cv = e.match(/\A[ \t]*([^ ]+[@][^ ]+) on[ \t]*.*\z/) ||
                      e.match(/\A[ \t]*.+(?:SMTP|smtp)=([^ ]+[@][^ ]+) on[ \t]*.*\z/)
                # kijitora@example.co.jp on Thu, 29 Apr 2007 16:51:51 -0500
                #   kijitora@example.com on 4/29/99 9:19:59 AM
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Bite.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                v['msexch'] = false
                recipients += 1

              elsif cv = e.match(/\A[ \t]+(MSEXCH:.+)\z/)
                #     MSEXCH:IMS:KIJITORA CAT:EXAMPLE:EXCHANGE 0 (000C05A6) Unknown Recipient
                v['diagnosis'] ||= ''
                v['diagnosis'] << cv[1]
              else
                next if v['msexch']
                if v['diagnosis'].to_s.start_with?('MSEXCH:')
                  # Continued from MEEXCH in the previous line
                  v['msexch'] = true
                  v['diagnosis'] << ' ' << e
                  statuspart = true
                else
                  # Error message in the body part
                  v['alterrors'] ||= ''
                  v['alterrors'] << ' ' << e
                end
              end
            else
              # Your message
              #
              #  To:      shironeko@example.jp
              #  Subject: ...
              #  Sent:    Thu, 29 Apr 2010 18:14:35 +0000
              #
              if cv = e.match(/\A[ \t]+To:[ \t]+(.+)\z/)
                #  To:      shironeko@example.jp
                next unless connheader['to'].empty?
                connheader['to'] = cv[1]
                connvalues += 1

              elsif cv = e.match(/\A[ \t]+Subject:[ \t]+(.+)\z/)
                #  Subject: ...
                next unless connheader['subject'].empty?
                connheader['subject'] = cv[1]
                connvalues += 1

              elsif cv = e.match(%r|\A[ \t]+Sent:[ \t]+([A-Z][a-z]{2},.+[-+]\d{4})\z|) ||
                         e.match(%r|\A[ \t]+Sent:[ \t]+(\d+[/]\d+[/]\d+[ \t]+\d+:\d+:\d+[ \t].+)|)
                #  Sent:    Thu, 29 Apr 2010 18:14:35 +0000
                #  Sent:    4/29/99 9:19:59 AM
                next unless connheader['date'].empty?
                connheader['date'] = cv[1]
                connvalues += 1
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          if cv = e['diagnosis'].match(/\AMSEXCH:.+[ \t]*[(]([0-9A-F]{8})[)][ \t]*(.*)\z/)
            #     MSEXCH:IMS:KIJITORA CAT:EXAMPLE:EXCHANGE 0 (000C05A6) Unknown Recipient
            capturedcode = cv[1]
            errormessage = cv[2]
            pseudostatus = ''

            ErrorCodes.each_key do |r|
              # Find captured code from the error code table
              next unless ErrorCodes[r].index(capturedcode)
              e['reason'] = r.to_s
              pseudostatus = Sisimai::SMTP::Status.code(r.to_s)
              e['status'] = pseudostatus unless pseudostatus.empty?
              break
            end
            e['diagnosis'] = errormessage
          end

          unless e['reason']
            # Could not detect the reason from the value of "diagnosis".
            if e['alterrors']
              # Copy alternative error message
              e['diagnosis'] = e['alterrors'] + ' ' + e['diagnosis']
              e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
              e.delete('alterrors')
            end
          end
          e['agent'] = self.smtpagent
          e.delete('msexch')
          e.each_key { |a| e[a] ||= '' }
        end

        if rfc822list.empty?
          # When original message does not included in the bounce message
          rfc822list << ('From: ' << connheader['to'])
          rfc822list << ('Date: ' << connheader['date'])
          rfc822list << ('Subject: ' << connheader['subject'])
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

