module Sisimai::Bite::Email
  module Office365
    # Sisimai::Bite::Email::Office365 parses a bounce email which created by
    # Microsoft Office 365.
    # Methods in the module are called from only Sisimai::Message.
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Office365.pm
      require 'sisimai/bite/email'

      Re0 = {
        :'subject'    => %r/Undeliverable:/,
        :'received'   => %r/.+[.](?:outbound[.]protection|prod)[.]outlook[.]com\b/,
        :'message-id' => %r/.+[.](?:outbound[.]protection|prod)[.]outlook[.]com\b/,
      }.freeze
      Re1 = {
        :begin  => %r{\A(?:
           Delivery[ ]has[ ]failed[ ]to[ ]these[ ]recipients[ ]or[ ]groups:
          |.+[ ]rejected[ ]your[ ]message[ ]to[ ]the[ ]following[ ]e[-]?mail[ ]addresses:
          )
        }x,
        :error  => %r/\ADiagnostic information for administrators:\z/,
        :eoerr  => %r/\AOriginal message headers:\z/,
        :rfc822 => %r|\AContent-Type: message/rfc822\z|,
        :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
      }.freeze
      CodeTable = {
        # https://support.office.com/en-us/article/Email-non-delivery-reports-in-Office-365-51daa6b9-2e35-49c4-a0c9-df85bf8533c3
        %r/\A4[.]4[.]7\z/        => 'expired',
        %r/\A4[.]7[.]26\z/       => 'securityerror',
        %r/\A4[.]7[.][56]\d\d\z/ => 'blocked',
        %r/\A4[.]7[.]8[5-9]\d\z/ => 'blocked',
        %r/\A5[.]1[.]0\z/        => 'userunknown',
        %r/\A5[.]4[.]1\z/        => 'norelaying',
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
      Indicators = Sisimai::Bite::Email.INDICATORS

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
      def pattern;     return Re0; end

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
        return nil unless mhead
        return nil unless mbody

        match  = 0
        match += 1 if mhead['subject'] =~ Re0[:subject]
        match += 1 if mhead['x-ms-exchange-message-is-ndr']
        match += 1 if mhead['x-microsoft-antispam-prvs']
        match += 1 if mhead['x-exchange-antispam-report-test']
        match += 1 if mhead['x-exchange-antispam-report-cfa-test']
        match += 1 if mhead['x-ms-exchange-crosstenant-originalarrivaltime']
        match += 1 if mhead['x-ms-exchange-crosstenant-fromentityheader']
        match += 1 if mhead['x-ms-exchange-transport-crosstenantheadersstamped']
        match += 1 if mhead['received'].find { |a| a =~ Re0[:received] }
        if mhead['message-id']
          # Message-ID: <00000000-0000-0000-0000-000000000000@*.*.prod.outlook.com>
          match += 1 if mhead['message-id'] =~ Re0[:'message-id']
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

        hasdivided.each do |e|
          if readcursor.zero?
            # Beginning of the bounce message or delivery status part
            if e =~ Re1[:begin]
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']).zero?
            # Beginning of the original message part
            if e =~ Re1[:rfc822]
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
            next if (readcursor & Indicators[:deliverystatus]).zero?
            next if e.empty?

            # kijitora@example.com<mailto:kijitora@example.com>
            # The email address wasn=92t found at the destination domain. It might be mis=
            # spelled or it might not exist any longer. Try retyping the address and rese=
            # nding the message.
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
                  htmlbegins = false if e =~ %r|\A[<]/html[>]|
                  next
                end

                if cv = e.match(/\A[Aa]ction:[ ]*(.+)\z/)
                  # Action: failed
                  v['action'] = cv[1].downcase

                elsif cv = e.match(/\A[Ss]tatus:[ ]*(\d[.]\d+[.]\d+)/)
                  # Status:5.2.0
                  v['status'] = cv[1]

                elsif cv = e.match(/\A[Rr]eporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Reporting-MTA: dns;BLU004-OMC3S13.hotmail.example.com
                  connheader['lhost'] = cv[1].downcase

                elsif cv = e.match(/\A[Rr]eceived-[Ff]rom-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Reporting-MTA: dns;BLU004-OMC3S13.hotmail.example.com
                  connheader['rhost'] = cv[1].downcase

                elsif cv = e.match(/\A[Aa]rrival-[Dd]ate:[ ]*(.+)\z/)
                  # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                  next if connheader['date']
                  connheader['date'] = cv[1]

                else
                  htmlbegins = true if e =~ /\A[<]html[>]/
                end

              else
                if e =~ Re1[:error]
                  # Diagnostic information for administrators:
                  v['diagnosis'] = e
                else
                  # kijitora@example.com
                  # Remote Server returned '550 5.1.10 RESOLVER.ADR.RecipientNotFound; Recipien=
                  # t not found by SMTP address lookup'
                  next unless v['diagnosis']
                  if e =~ Re1[:eoerr]
                    # Original message headers:
                    endoferror = true
                    next
                  end
                  v['diagnosis'] += ' ' + e
                end
              end
            end

          end
        end

        return nil if recipients.zero?
        require 'sisimai/string'
        require 'sisimai/smtp/status'

        dscontents.map do |e|
          # Set default values if each value is empty.
          connheader.each_key { |a| e[a] ||= connheader[a] || '' }

          e['agent']     = self.smtpagent
          e['status']  ||= ''
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''

          if e['status'].empty? || e['status'] =~ /\A\d[.]0[.]0\z/
            # There is no value of Status header or the value is 5.0.0, 4.0.0
            pseudostatus = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['status'] = pseudostatus if pseudostatus.size > 0
          end

          if e['status']
            CodeTable.each_key do |f|
              # Try to match with each key as a regular expression
              next unless e['status'] =~ f
              e['reason'] = CodeTable[f]
              break
            end
          end
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

