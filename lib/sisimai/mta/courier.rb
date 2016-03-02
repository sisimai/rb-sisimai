module Sisimai
  module MTA
    # Sisimai::MTA::Courier parses a bounce email which created by Courier MTA.
    # Methods in the module are called from only Sisimai::Message.
    module Courier
      # Imported from p5-Sisimail/lib/Sisimai/MTA/Courier.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        # http://www.courier-mta.org/courierdsn.html
        # courier/module.dsn/dsn*.txt
        Re0 = {
          :'from'       => %r/Courier mail server at /,
          :'subject'    => %r{(?:
             NOTICE:[ ]mail[ ]delivery[ ]status[.]
            |WARNING:[ ]delayed[ ]mail[.]
            )
          }x,
          :'message-id' => %r/\A[<]courier[.][0-9A-F]+[.]/,
        }
        Re1 = {
          :begin  => %r{(?:
             DELAYS[ ]IN[ ]DELIVERING[ ]YOUR[ ]MESSAGE
            |UNDELIVERABLE[ ]MAIL
            )
          }x,
          :rfc822 => %r{\AContent-Type:[ ]*(?:
             message/rfc822
            |text/rfc822-headers
            )\z
          }x,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReFailure = {
          # courier/module.esmtp/esmtpclient.c:526| hard_error(del, ctf, "No such domain.");
          'hostunknown' => %r{
            \ANo[ ]such[ ]domain[.]\z
          }x,
          # courier/module.esmtp/esmtpclient.c:531| hard_error(del, ctf,
          # courier/module.esmtp/esmtpclient.c:532|  "This domain's DNS violates RFC 1035.");
          'systemerror' => %r{
            \AThis[ ]domain's[ ]DNS[ ]violates[ ]RFC[ ]1035[.]\z
          }x,
        }
        ReDelayed = {
          # courier/module.esmtp/esmtpclient.c:535| soft_error(del, ctf, "DNS lookup failed.");
          'networkerror' => %r{
            \ADNS[ ]lookup[ ]failed[.]\z
          },
        }
        Indicators = Sisimai::MTA.INDICATORS

        def description; return 'Courier MTA'; end
        def smtpagent;   return 'Courier'; end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from Courier MTA
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
          match += 1 if mhead['from']    =~ Re0[:from]
          match += 1 if mhead['subject'] =~ Re0[:subject]
          if mhead['message-id']
            # Message-ID: <courier.4D025E3A.00001792@5jo.example.org>
            match += 1 if mhead['message-id'] =~ Re0[:'message-id']
          end
          return nil if match == 0

          dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          havepassed = ['']
          rfc822part = ''     # (String) message/rfc822-headers part
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          commandtxt = ''     # (String) SMTP Command name begin with the string '>>>'
          connvalues = 0      # (Integer) Flag, 1 if all the value of $connheader have been set
          connheader = {
            'date'  => '',    # The value of Arrival-Date header
            'rhost' => '',    # The value of Reporting-MTA header
            'lhost' => '',    # The value of Received-From-MTA header
          }
          v = nil

          hasdivided.each do |e|
            # Save the current line for the next loop
            havepassed << e; p = havepassed[-2]

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

              if connvalues == connheader.keys.size
                # Final-Recipient: rfc822; kijitora@example.co.jp
                # Action: failed
                # Status: 5.0.0
                # Remote-MTA: dns; mx.example.co.jp [192.0.2.95]
                # Diagnostic-Code: smtp; 550 5.1.1 <kijitora@example.co.jp>... User Unknown
                v = dscontents[-1]

                if cv = e.match(/\A[Ff]inal-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                  # Final-Recipient: rfc822; kijitora@example.co.jp
                  if v['recipient']
                    # There are multiple recipient addresses in the message body.
                    dscontents << Sisimai::MTA.DELIVERYSTATUS
                    v = dscontents[-1]
                  end
                  v['recipient'] = cv[1]
                  recipients += 1

                elsif cv = e.match(/\A[Xx]-[Aa]ctual-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                  # X-Actual-Recipient: RFC822; kijitora@example.co.jp
                  v['alias'] = cv[1]

                elsif cv = e.match(/\A[Aa]ction:[ ]*(.+)\z/)
                  # Action: failed
                  v['action'] = cv[1].downcase

                elsif cv = e.match(/\A[Ss]tatus:[ ]*(\d[.]\d+[.]\d+)/)
                  # Status: 5.1.1
                  # Status:5.2.0
                  # Status: 5.1.0 (permanent failure)
                  v['status'] = cv[1]

                elsif cv = e.match(/\A[Rr]emote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Remote-MTA: DNS; mx.example.jp
                  v['rhost'] = cv[1].downcase
                  if v['rhost'] =~ / /
                    # Get the first element
                    v['rhost'] = v['rhost'].split(' ').shift
                  end

                elsif cv = e.match(/\A[Ll]ast-[Aa]ttempt-[Dd]ate:[ ]*(.+)\z/)
                  # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
                  v['date'] = cv[1]

                else
                  if cv = e.match(/\A[Dd]iagnostic-[Cc]ode:[ ]*(.+?);[ ]*(.+)\z/)
                    # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                    v['spec'] = cv[1].upcase
                    v['diagnosis'] = cv[2]

                  elsif p =~ /\A[Dd]iagnostic-[Cc]ode:[ ]*/ && cv = e.match(/\A[ \t]+(.+)\z/)
                    # Continued line of the value of Diagnostic-Code header
                    v['diagnosis'] ||= ''
                    v['diagnosis']  += ' ' + cv[1]
                    havepassed[-1] = 'Diagnostic-Code: ' + e
                  end
                end

              else
                # This is a delivery status notification from marutamachi.example.org,
                # running the Courier mail server, version 0.65.2.
                #
                # The original message was received on Sat, 11 Dec 2010 12:19:57 +0900
                # from [127.0.0.1] (c10920.example.com [192.0.2.20])
                #
                # ---------------------------------------------------------------------------
                #
                #                           UNDELIVERABLE MAIL
                #
                # Your message to the following recipients cannot be delivered:
                #
                # <kijitora@example.co.jp>:
                #    mx.example.co.jp [74.207.247.95]:
                # >>> RCPT TO:<kijitora@example.co.jp>
                # <<< 550 5.1.1 <kijitora@example.co.jp>... User Unknown
                #
                # ---------------------------------------------------------------------------
                if cv = e.match(/\A[>]{3}[ ]+([A-Z]{4})[ ]?/)
                  # >>> DATA
                  next if commandtxt.size > 0
                  commandtxt = cv[1]

                elsif cv = e.match(/\A[Rr]eporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Reporting-MTA: dns; mx.example.jp
                  next if connheader['rhost'].size > 0
                  connheader['rhost'] = cv[1].downcase
                  connvalues += 1

                elsif cv = e.match(/\A[Rr]eceived-[Ff]rom-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Received-From-MTA: DNS; x1x2x3x4.dhcp.example.ne.jp
                  next if connheader['lhost'].size > 0
                  connheader['lhost'] = cv[1].downcase
                  connvalues += 1

                elsif cv = e.match(/\A[Aa]rrival-[Dd]ate:[ ]*(.+)\z/)
                  # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                  next if connheader['date'].size > 0
                  connheader['date'] = cv[1]
                  connvalues += 1
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
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              %w|lhost rhost|.each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end

            ReFailure.each_key do |r|
              # Verify each regular expression of session errors
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r
              e['softbounce'] = 0
              break
            end

            unless e['reason']
              ReDelayed.each_key do |r|
                # Verify each regular expression of session errors
                next unless e['diagnosis'] =~ ReDelayed[r]
                e['reason'] = r
                e['softbounce'] = 1
                break
              end
            end

            if !e['status'] || e['status'] =~ /\d[.]0[.]0\z/
              # Get the status code from the respnse of remote MTA.
              f = Sisimai::SMTP::Status.find(e['diagnosis'])
              e['status'] = f if f.size > 0
            end
            e['spec']      = '' unless e['spec'] =~ /\A(?:SMTP|X-UNIX)\z/
            e['agent']     = Sisimai::MTA::Courier.smtpagent
            e['command'] ||= commandtxt || ''
            e.each_key { |a| e[a] ||= '' }
          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

