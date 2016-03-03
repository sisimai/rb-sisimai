module Sisimai
  module MTA
    # Sisimai::MTA::X5 parses a bounce email which created by Unknown MTA #5.
    # Methods in the module are called from only Sisimai::Message.
    module X5
      # Imported from p5-Sisimail/lib/Sisimai/MTA/X5.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :from => %r/\bTWFpbCBEZWxpdmVyeSBTdWJzeXN0ZW0\b/,
          :to   => %r/\bNotificationRecipients\b/,
        }
        Re1 = {
          :begin  => %r|\AContent-Type: message/delivery-status|,
          :rfc822 => %r|\AContent-Type: message/rfc822|,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        Indicators = Sisimai::MTA.INDICATORS

        def description; return 'Unknown MTA #5'; end
        def smtpagent;   return 'X5'; end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from Unknown MTA #5
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
          match = 0

          # To: "NotificationRecipients" <...>
          match += 1 if mhead['to'] && mhead['to'] =~ Re0[:to]

          require 'sisimai/mime'
          if mhead['from'] =~ Re0[:from]
            # From: "=?iso-2022-jp?B?TWFpbCBEZWxpdmVyeSBTdWJzeXN0ZW0=?=" <...>
            #       Mail Delivery Subsystem
            mhead['from'].split(' ').each do |f|
              # Check each element of From: header
              next unless Sisimai::MIME.is_mimeencoded(f)
              match += 1 if Sisimai::MIME.mimedecode([f]) =~ /Mail Delivery Subsystem/
              break
            end
          end

          if Sisimai::MIME.is_mimeencoded(mhead['subject'])
            # Subject: =?iso-2022-jp?B?UmV0dXJuZWQgbWFpbDogVXNlciB1bmtub3du?=
            plain = Sisimai::MIME.mimedecode([mhead['subject']])
            match += 1 if plain =~ /Mail Delivery Subsystem/
          end
          return nil if match < 2

          dscontents = [Sisimai::MTA.DELIVERYSTATUS]
          hasdivided = mbody.split("\n")
          havepassed = ['']
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          v = nil

          hasdivided.each do |e|
            # Save the current line for the next loop
            havepassed << e
            p = havepassed[-2]

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
              # Before "message/rfc822"
              next if e.empty?
              v = dscontents[-1]

              if cv = e.match(/\A[Ff]inal-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # Final-Recipient: RFC822; kijitora@example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              elsif cv = e.match(/\A[Xx]-[Aa]ctual-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/) ||
                    cv = e.match(/\A[Oo]riginal-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/)
                # X-Actual-Recipient: RFC822; kijitora@example.co.jp
                # Original-Recipient: rfc822;kijitora@example.co.jp
                v['alias'] = cv[1]

              elsif cv = e.match(/\A[Aa]ction:[ ]*(.+)\z/)
                # Action: failed
                v['action'] = cv[1].downcase

              elsif cv = e.match(/\A[Ss]tatus:[ ]*(\d[.]\d+[.]\d+)/)
                # Status: 5.1.1
                v['status'] = cv[1]

              elsif cv = e.match(/\A[Rr]eporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Reporting-MTA: dns; mx.example.jp
                v['lhost'] = cv[1].downcase

              elsif cv = e.match(/\A[Rr]emote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                # Remote-MTA: DNS; mx.example.jp
                v['rhost'] = cv[1].downcase

              elsif cv = e.match(/\A[Ll]ast-[Aa]ttempt-[Dd]ate:[ ]*(.+)\z/)
                # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
                v['date'] = cv[1]

              else
                # Get an error message from Diagnostic-Code: field
                if cv = e.match(/\A[Dd]iagnostic-[Cc]ode:[ ]*(.+?);[ ]*(.+)\z/)
                  # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                  v['spec'] = cv[1].downcase
                  v['diagnosis'] = cv[2]

                elsif p =~ /\A[Dd]iagnostic-[Cc]ode:[ ]*/ && cv = e.match(/\A[ \t]+(.+)\z/)
                  # Continued line of the value of Diagnostic-Code header
                  v['diagnosis'] ||= ''
                  v['diagnosis']  += ' ' + cv[1]
                  havepassed[-1] = 'Diagnostic-Code: ' + e
                end
              end
            else
              # After "message/rfc822"
              next if recipients == 0
              next if readcursor & Indicators['deliverystatus'] == 0

              if e.empty?
                blanklines += 1
                break if blanklines > 1
                next
              end
              rfc822list << e

            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['agent'] = Sisimai::MTA::X5.smtpagent

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              %w|lhost rhost|.each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] ||= Sisimai::String.sweep(e['diagnosis'])
            e['status']    ||= Sisimai::SMTP::Status.find(e['diagnosis'])
            e['spec']      ||= e['reason'] == 'mailererror' ? 'X-UNIX' : 'SMTP'
            e['action']    ||= 'failed' if e['status'] =~ /\A[45]/
            e.each_key { |a| e[a] ||= '' }
          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

