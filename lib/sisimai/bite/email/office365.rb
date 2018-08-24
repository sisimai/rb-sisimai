module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Office365 parses a bounce email which created by
  # Microsoft Office 365.
  # Methods in the module are called from only Sisimai::Message.
  module Office365
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Office365.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        rfc822: ['Content-Type: message/rfc822'],
        error:  ['Diagnostic information for administrators:'],
        eoerr:  ['Original message headers:'],
      }.freeze
      MarkingsOf = {
        message: %r{\A(?:
           Delivery[ ]has[ ]failed[ ]to[ ]these[ ]recipients[ ]or[ ]groups:
          |.+[ ]rejected[ ]your[ ]message[ ]to[ ]the[ ]following[ ]e[-]?mail[ ]addresses:
          )
        }x,
      }.freeze
      StatusList = {
        # https://support.office.com/en-us/article/Email-non-delivery-reports-in-Office-365-51daa6b9-2e35-49c4-a0c9-df85bf8533c3
        %r/\A4[.]4[.]7\z/        => 'expired',
        %r/\A4[.]4[.]312\z/      => 'networkerror',
        %r/\A4[.]4[.]316\z/      => 'expired',
        %r/\A4[.]7[.]26\z/       => 'securityerror',
        %r/\A4[.]7[.][56]\d\d\z/ => 'blocked',
        %r/\A4[.]7[.]8[5-9]\d\z/ => 'blocked',
        %r/\A5[.]4[.]1\z/        => 'norelaying',
        %r/\A5[.]4[.]312\z/      => 'networkerror',
        %r/\A5[.]4[.]316\z/      => 'expired',
        %r/\A5[.]4[.]6\z/        => 'networkerror',
        %r/\A5[.]6[.]11\z/       => 'contenterror',
        %r/\A5[.]7[.]1\z/        => 'rejected',
        %r/\A5[.]7[.]1[23]\z/    => 'rejected',
        %r/\A5[.]7[.]124\z/      => 'rejected',
        %r/\A5[.]7[.]13[3-6]\z/  => 'rejected',
        %r/\A5[.]7[.]25\z/       => 'networkerror',
        %r/\A5[.]7[.]50[1-3]\z/  => 'spamdetected',
        %r/\A5[.]7[.]50[4-5]\z/  => 'filtered',
        %r/\A5[.]7[.]50[6-7]\z/  => 'blocked',
        %r/\A5[.]7[.]508\z/      => 'toomanyconn',
        %r/\A5[.]7[.]509\z/      => 'securityerror',
        %r/\A5[.]7[.]510\z/      => 'notaccept',
        %r/\A5[.]7[.]511\z/      => 'rejected',
        %r/\A5[.]7[.]512\z/      => 'securityerror',
        %r/\A5[.]7[.]60[6-9]\z/  => 'blocked',
        %r/\A5[.]7[.]6[1-4]\d\z/ => 'blocked',
        %r/\A5[.]7[.]7[0-4]\d\z/ => 'toomanyconn',
      }.freeze
      ReCommands = {
        RCPT: %r/unknown recipient or mailbox unavailable ->.+[<]?.+[@].+[.][a-zA-Z]+[>]?/,
      }.freeze

      def description; return 'Microsoft Office 365: http://office.microsoft.com/'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end

      def headerlist
        # X-MS-Exchange-Message-Is-Ndr:
        # X-Microsoft-Antispam-PRVS: <....@...outlook.com>
        # X-Exchange-Antispam-Report-Test: UriScan:;
        # X-Exchange-Antispam-Report-CFA-Test:
        # X-MS-Exchange-CrossTenant-OriginalArrivalTime: 29 Apr 2015 23:34:45.6789 (JST)
        # X-MS-Exchange-CrossTenant-FromEntityHeader: Hosted
        # X-MS-Exchange-Transport-CrossTenantHeadersStamped: ...
        return [
          'X-MS-Exchange-Message-Is-Ndr',
          'X-Microsoft-Antispam-PRVS',
          'X-Exchange-Antispam-Report-Test',
          'X-Exchange-Antispam-Report-CFA-Test',
          'X-MS-Exchange-CrossTenant-OriginalArrivalTime',
          'X-MS-Exchange-CrossTenant-FromEntityHeader',
          'X-MS-Exchange-Transport-CrossTenantHeadersStamped',
        ]
      end

      # Parse bounce messages from Microsoft Office 365
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
        tryto  = %r/.+[.](?:outbound[.]protection|prod)[.]outlook[.]com\b/
        match  = 0
        match += 1 if mhead['subject'].include?('Undeliverable:')
        match += 1 if mhead['x-ms-exchange-message-is-ndr']
        match += 1 if mhead['x-microsoft-antispam-prvs']
        match += 1 if mhead['x-exchange-antispam-report-test']
        match += 1 if mhead['x-exchange-antispam-report-cfa-test']
        match += 1 if mhead['x-ms-exchange-crosstenant-originalarrivaltime']
        match += 1 if mhead['x-ms-exchange-crosstenant-fromentityheader']
        match += 1 if mhead['x-ms-exchange-transport-crosstenantheadersstamped']
        match += 1 if mhead['received'].any? { |a| a =~ tryto }
        if mhead['message-id']
          # Message-ID: <00000000-0000-0000-0000-000000000000@*.*.prod.outlook.com>
          match += 1 if mhead['message-id'] =~ tryto
        end
        return nil if match < 2

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        connheader = {}
        endoferror = false  # (Boolean) Flag for the end of error messages
        htmlbegins = false  # (Boolean) Flag for HTML part
        v = nil

        while e = hasdivided.shift do
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e =~ MarkingsOf[:message]
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

            # kijitora@example.com<mailto:kijitora@example.com>
            # The email address wasn't found at the destination domain. It might
            # be misspelled or it might not exist any longer. Try retyping the
            # address and resending the message.
            v = dscontents[-1]

            if cv = e.match(/\A.+[@].+[<]mailto:(.+[@].+)[>]\z/)
              # kijitora@example.com<mailto:kijitora@example.com>
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              recipients += 1

            elsif cv = e.match(/\AGenerating server: (.+)\z/)
              # Generating server: FFFFFFFFFFFF.e0.prod.outlook.com
              connheader['lhost'] = cv[1].downcase
            else
              if endoferror
                # After "Original message headers:"
                if htmlbegins
                  # <html> .. </html>
                  htmlbegins = false if e.start_with?('</html>')
                  next
                end

                if cv = e.match(/\AAction:[ ]*(.+)\z/)
                  # Action: failed
                  v['action'] = cv[1].downcase

                elsif cv = e.match(/\AStatus:[ ]*(\d[.]\d+[.]\d+)/)
                  # Status:5.2.0
                  v['status'] = cv[1]

                elsif cv = e.match(/\AReporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Reporting-MTA: dns;BLU004-OMC3S13.hotmail.example.com
                  connheader['lhost'] = cv[1].downcase

                elsif cv = e.match(/\AReceived-From-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Reporting-MTA: dns;BLU004-OMC3S13.hotmail.example.com
                  connheader['rhost'] = cv[1].downcase

                elsif cv = e.match(/\AArrival-Date:[ ]*(.+)\z/)
                  # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                  next if connheader['date']
                  connheader['date'] = cv[1]
                else
                  htmlbegins = true if e.start_with?('<html>')
                end
              else
                if e == StartingOf[:error][0]
                  # Diagnostic information for administrators:
                  v['diagnosis'] = e
                else
                  # kijitora@example.com
                  # Remote Server returned '550 5.1.10 RESOLVER.ADR.RecipientNotFound; Recipien=
                  # t not found by SMTP address lookup'
                  next unless v['diagnosis']
                  if e == StartingOf[:eoerr][0]
                    # Original message headers:
                    endoferror = true
                    next
                  end
                  v['diagnosis'] << ' ' << e
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
          e['status']  ||= ''
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''

          if e['status'].empty? || e['status'].end_with?('.0.0')
            # There is no value of Status header or the value is 5.0.0, 4.0.0
            pseudostatus = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['status'] = pseudostatus unless pseudostatus.empty?
          end

          ReCommands.each_key do |p|
            # Try to match with regular expressions defined in ReCommands
            next unless e['diagnosis'] =~ ReCommands[p]
            e['command'] = p.to_s
            break
          end
          next unless e['status']

          StatusList.each_key do |f|
            # Try to match with each key as a regular expression
            next unless e['status'] =~ f
            e['reason'] = StatusList[f]
            break
          end
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

