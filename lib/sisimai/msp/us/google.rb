module Sisimai
  module MSP::US
    # Sisimai::MSP::US::Google parses a bounce email which created by Gmail.
    # Methods in the module are called from only Sisimai::Message.
    module Google
      # Imported from p5-Sisimail/lib/Sisimai/MSP/US/Google.pm
      class << self
        require 'sisimai/msp'
        require 'sisimai/rfc5322'

        Re0 = {
          :from    => %r/[@]googlemail[.]com[>]?\z/,
          :subject => %r/Delivery[ ]Status[ ]Notification/,
        }
        Re1 = {
          :begin   => %r/Delivery to the following recipient/,
          :start   => %r/Technical details of (?:permanent|temporary) failure:/,
          :error   => %r/The error that the other server returned was:/,
          :rfc822  => %r{\A(?:
               -----[ ]Original[ ]message[ ]-----
              |[ \t]*-----[ ]Message[ ]header[ ]follows[ ]-----
              )\z
          }x,
          :endof   => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReFailure = {
          'expired' => %r{(?:
               DNS[ ]Error:[ ]Could[ ]not[ ]contact[ ]DNS[ ]servers
              |Delivery[ ]to[ ]the[ ]following[ ]recipient[ ]has[ ]been[ ]delayed
              |The[ ]recipient[ ]server[ ]did[ ]not[ ]accept[ ]our[ ]requests[ ]to[ ]connect
              )
          }x,
          'hostunknown' => %r{DNS[ ]Error:[ ](?:
               Domain[ ]name[ ]not[ ]found
              |DNS[ ]server[ ]returned[ ]answer[ ]with[ ]no[ ]data
              )
          }x,
        }
        StateTable = {
          # Technical details of permanent failure:
          # Google tried to deliver your message, but it was rejected by the recipient domain.
          # We recommend contacting the other email provider for further information about the
          # cause of this error. The error that the other server returned was:
          # 500 Remote server does not support TLS (state 6).
          '6'  => { 'command' => 'MAIL', 'reason' => 'systemerror' },

          # http://www.google.td/support/forum/p/gmail/thread?tid=08a60ebf5db24f7b&hl=en
          # Technical details of permanent failure:
          # Google tried to deliver your message, but it was rejected by the recipient domain.
          # We recommend contacting the other email provider for further information about the
          # cause of this error. The error that the other server returned was:
          # 535 SMTP AUTH failed with the remote server. (state 8).
          '8'  => { 'command' => 'AUTH', 'reason' => 'systemerror' },

          # http://www.google.co.nz/support/forum/p/gmail/thread?tid=45208164dbca9d24&hl=en
          # Technical details of temporary failure:
          # Google tried to deliver your message, but it was rejected by the recipient domain.
          # We recommend contacting the other email provider for further information about the
          # cause of this error. The error that the other server returned was:
          # 454 454 TLS missing certificate: error:0200100D:system library:fopen:Permission denied (#4.3.0) (state 9).
          '9'  => { 'command' => 'AUTH', 'reason' => 'systemerror' },

          # http://www.google.com/support/forum/p/gmail/thread?tid=5cfab8c76ec88638&hl=en
          # Technical details of permanent failure:
          # Google tried to deliver your message, but it was rejected by the recipient domain.
          # We recommend contacting the other email provider for further information about the
          # cause of this error. The error that the other server returned was:
          # 500 Remote server does not support SMTP Authenticated Relay (state 12).
          '12' => { 'command' => 'AUTH', 'reason' => 'relayingdenied' },

          # Technical details of permanent failure:
          # Google tried to deliver your message, but it was rejected by the recipient domain.
          # We recommend contacting the other email provider for further information about the
          # cause of this error. The error that the other server returned was:
          # 550 550 5.7.1 <****@gmail.com>... Access denied (state 13).
          '13' => { 'command' => 'EHLO', 'reason' => 'blocked' },

          # Technical details of permanent failure:
          # Google tried to deliver your message, but it was rejected by the recipient domain.
          # We recommend contacting the other email provider for further information about the
          # cause of this error. The error that the other server returned was:
          # 550 550 5.1.1 <******@*********.**>... User Unknown (state 14).
          # 550 550 5.2.2 <*****@****.**>... Mailbox Full (state 14).
          #
          '14' => { 'command' => 'RCPT', 'reason' => 'userunknown' },

          # http://www.google.cz/support/forum/p/gmail/thread?tid=7090cbfd111a24f9&hl=en
          # Technical details of permanent failure:
          # Google tried to deliver your message, but it was rejected by the recipient domain.
          # We recommend contacting the other email provider for further information about the
          # cause of this error. The error that the other server returned was:
          # 550 550 5.7.1 SPF unauthorized mail is prohibited. (state 15).
          # 554 554 Error: no valid recipients (state 15).
          '15' => { 'command' => 'DATA', 'reason' => 'filtered' },

          # http://www.google.com/support/forum/p/Google%20Apps/thread?tid=0aac163bc9c65d8e&hl=en
          # Technical details of permanent failure:
          # Google tried to deliver your message, but it was rejected by the recipient domain.
          # We recommend contacting the other email provider for further information about the
          # cause of this error. The error that the other server returned was:
          # 550 550 <****@***.**> No such user here (state 17).
          # 550 550 #5.1.0 Address rejected ***@***.*** (state 17).
          '17' => { 'command' => 'DATA', 'reason' => 'filtered' },

          # Technical details of permanent failure:
          # Google tried to deliver your message, but it was rejected by the recipient domain.
          # We recommend contacting the other email provider for further information about the
          # cause of this error. The error that the other server returned was:
          # 550 550 Unknown user *****@***.**.*** (state 18).
          '18' => { 'command' => 'DATA', 'reason' => 'filtered' },
        }
        Indicators = Sisimai::MSP.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'Google Gmail: https://mail.google.com'; end
        def smtpagent;   return 'US::Google'; end
        def headerlist;  return ['X-Failed-Recipients']; end
        def pattern;     return Re0; end

        # Parse bounce messages from Google Gmail
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

          # Google Mail
          # From: Mail Delivery Subsystem <mailer-daemon@googlemail.com>
          # Received: from vw-in-f109.1e100.net [74.125.113.109] by ...
          #
          # * Check the body part
          #   This is an automatically generated Delivery Status Notification
          #   Delivery to the following recipient failed permanently:
          #
          #        recipient-address-here@example.jp
          #
          #   Technical details of permanent failure:
          #   Google tried to deliver your message, but it was rejected by the
          #   recipient domain. We recommend contacting the other email provider
          #   for further information about the cause of this error. The error
          #   that the other server returned was:
          #   550 550 <recipient-address-heare@example.jp>: User unknown (state 14).
          #
          #   -- OR --
          #   THIS IS A WARNING MESSAGE ONLY.
          #
          #   YOU DO NOT NEED TO RESEND YOUR MESSAGE.
          #
          #   Delivery to the following recipient has been delayed:
          #
          #        mailboxfull@example.jp
          #
          #   Message will be retried for 2 more day(s)
          #
          #   Technical details of temporary failure:
          #   Google tried to deliver your message, but it was rejected by the recipient
          #   domain. We recommend contacting the other email provider for further infor-
          #   mation about the cause of this error. The error that the other server re-
          #   turned was: 450 450 4.2.2 <mailboxfull@example.jp>... Mailbox Full (state 14).
          #
          #   -- OR --
          #
          #   Delivery to the following recipient failed permanently:
          #
          #        userunknown@example.jp
          #
          #   Technical details of permanent failure:=20
          #   Google tried to deliver your message, but it was rejected by the server for=
          #    the recipient domain example.jp by mx.example.jp. [192.0.2.59].
          #
          #   The error that the other server returned was:
          #   550 5.1.1 <userunknown@example.jp>... User Unknown
          #
          return nil unless mhead['from']    =~ Re0[:from]
          return nil unless mhead['subject'] =~ Re0[:subject]

          require 'sisimai/address'
          dscontents = []; dscontents << Sisimai::MSP.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          statecode0 = 0      # (Integer) The value of (state *) in the error message
          v = nil

          hasdivided.each do |e|
            if readcursor == 0
              # Beginning of the bounce message or delivery status part
              if e =~ Re1[:begin]
                readcursor |= Indicators[:'deliverystatus']
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
              if cv = e.match(/\A([-0-9A-Za-z]+?)[:][ ]*.+\z/)
                # Skip if DKIM-Signature header
                next if e =~ /\ADKIM-Signature[:]/

                # Get required headers only
                lhs = cv[1].downcase
                previousfn = '';
                next unless RFC822Head.key?(lhs)

                previousfn  = lhs
                rfc822part += e + "\n"

              elsif e =~ /\A[ \t]+/
                # Continued line from the previous line
                next if rfc822next[previousfn]
                rfc822part += e + "\n" if LongFields.key?(previousfn)

              else
                # Check the end of headers in rfc822 part
                next unless LongFields.key?(previousfn)
                next unless e.empty?
                rfc822next[previousfn] = true
              end

            else
              # Before "message/rfc822"
              next if readcursor & Indicators[:'deliverystatus'] == 0
              next if e.empty?

              # Technical details of permanent failure:=20
              # Google tried to deliver your message, but it was rejected by the recipient =
              # domain. We recommend contacting the other email provider for further inform=
              # ation about the cause of this error. The error that the other server return=
              # ed was: 554 554 5.7.0 Header error (state 18).
              #
              # -- OR --
              #
              # Technical details of permanent failure:=20
              # Google tried to deliver your message, but it was rejected by the server for=
              # the recipient domain example.jp by mx.example.jp. [192.0.2.49].
              #
              # The error that the other server returned was:
              # 550 5.1.1 <userunknown@example.jp>... User Unknown
              #
              v = dscontents[-1]

              if cv = e.match(/\A[ \t]+([^ ]+[@][^ ]+)\z/)
                # kijitora@example.jp: 550 5.2.2 <kijitora@example>... Mailbox Full
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MSP.DELIVERYSTATUS
                  v = dscontents[-1]
                end

                addr0 = Sisimai::Address.s3s4(cv[1])
                if Sisimai::RFC5322.is_emailaddress(addr0)
                  v['recipient'] = addr0
                  recipients += 1
                end

              else
                if cv = e.match(/Technical details of (.+) failure:/)
                  # Technical details of permanent failure:
                  # Technical details of temporary failure:
                  v['softbounce'] = cv[1] == 'permanent' ? 0 : 1
                end
                v['diagnosis'] ||= ''
                v['diagnosis']  += e + ' '
              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            unless e['rhost']
              # Get the value of remote host
              if cv = e['diagnosis'].match(/[ \t]+by[ \t]+([^ ]+)[.][ \t]+\[(\d+[.]\d+[.]\d+[.]\d+)\][.]/)
                # Google tried to deliver your message, but it was rejected by
                # the server for the recipient domain example.jp by mx.example.jp. [192.0.2.153].
                hostname = cv[1]
                ipv4addr = cv[2]
                if hostname =~ /[-0-9a-zA-Z]+[.][a-zA-Z]+\z/
                  # Maybe valid hostname
                  e['rhost'] = hostname.downcase
                else
                  # Use IP address instead
                  e['rhost'] = ipv4addr
                end
              end
            end

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              ['lhost', 'rhost'].each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end

            if cv = e['diagnosis'].match(/[(]state[ ](\d+)[)][.]/)
              statecode0 = cv[1]
            end
            if StateTable[statecode0]
              # (state *)
              e['reason']  = StateTable[statecode0]['reason']
              e['command'] = StateTable[statecode0]['command']

            else
              # No state code
              ReFailure.each_key do |r|
                # Verify each regular expression of session errors
                next unless e['diagnosis'] =~ ReFailure[r]
                e['reason'] = r
                break
              end
            end
            e['status'] = Sisimai::SMTP::Status.find(e['diagnosis'])

            if e['reason']
              # Set pseudo status code
              if e['status'] =~ /\A[45][.][1-7][.][1-9]\z/
                # Override bounce reason
                e['reason'] = Sisimai::SMTP::Status.name(e['status'])
              end
            end
            e['spec']   = e['reason'] == 'mailererror' ? 'X-UNIX' : 'SMTP'
            e['action'] = 'failed' if e['status'] =~ /\A[45]/
            e['agent']  = Sisimai::MSP::US::Google.smtpagent
          end

          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

