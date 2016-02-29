module Sisimai
  module MSP::US
    # Sisimai::MSP::US::Office365 parses a bounce email which created by Microsoft
    # Office 365. Methods in the module are called from only Sisimai::Message.
    module Office365
      # Imported from p5-Sisimail/lib/Sisimai/MSP/US/Office365.pm
      class << self
        require 'sisimai/msp'
        require 'sisimai/rfc5322'

        Re0 = {
          :subject  => %r/Undeliverable:/,
          :received => %r/.+[.](?:outbound[.]protection|prod)[.]outlook[.]com\b/,
        }
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
        }
        CodeTable = {
          '4.4.7'   => 'expired',
          '5.1.0'   => 'rejected',
          '5.1.1'   => 'userunknown',
          '5.1.10'  => 'filtered',
          '5.4.1'   => 'networkerror',
          '5.4.14'  => 'networkerror',
          '5.7.1'   => 'rejected',
          '5.7.133' => 'rejected',
        }
        Indicators = Sisimai::MSP.INDICATORS

        def description; return 'Microsoft Office 365: http://office.microsoft.com/'; end
        def smtpagent;   return 'US::Office365'; end

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
        # @param         [Hash] mhead       Message header of a bounce email
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
          return nil if match < 2

          if mbody =~ /^Content-Transfer-Encoding: quoted-printable$/
            # This is a multi-part message in MIME format. Your mail reader does not
            # understand MIME message format.
            # --=_gy7C4Gpes0RP4V5Bs9cK4o2Us2ZT57b-3OLnRN+4klS8dTmQ
            # Content-Type: text/plain; charset=iso-8859-15
            # Content-Transfer-Encoding: quoted-printable
            require 'sisimai/mime'
            mbody = mbody.sub(/\A.+?quoted-printable/ms, '')
            mbody = Sisimai::MIME.qprintd(mbody)
          end

          dscontents = []; dscontents << Sisimai::MSP.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          rfc822part = ''     # (String) message/rfc822-headers part
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          connheader = {}
          endoferror = false  # (Boolean) Flag for the end of error messages
          htmlbegins = false  # (Boolean) Flag for HTML part
          v = nil

          hasdivided.each do |e|
            if readcursor == 0
              # Beginning of the bounce message or delivery status part
              if e =~ Re1[:begin]
                readcursor |= Indicators[:'deliverystatus']
                next
              end
            end

            if readcursor & Indicators[:'message-rfc822'] == 0
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
              next if readcursor & Indicators[:'deliverystatus'] == 0
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
                  dscontents << Sisimai::MSP.DELIVERYSTATUS
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

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            # Set default values if each value is empty.
            connheader.each_key { |a| e[a] ||= connheader[a] || '' }

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              %w|lhost rhost|.each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end

            e['spec']    ||= 'SMTP'
            e['status']  ||= ''
            e['agent']     = Sisimai::MSP::US::Office365.smtpagent
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''

            if e['status'].empty? || e['status'] =~ /\A\d[.]0[.]0\z/
              # There is no value of Status header or the value is 5.0.0, 4.0.0
              pseudostatus = Sisimai::SMTP::Status.find(e['diagnosis'])
              e['status'] = pseudostatus if pseudostatus.size > 0
            end

            if e['status']
              e['reason'] = CodeTable[e['status']] || ''
            end
          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

