module Sisimai
  module MTA
    # Sisimai::MTA::InterScanMSS parses a bounce email which created by Trend
    # Micro InterScan Messaging Security Suite. Methods in the module are called
    # from only Sisimai::Message.
    module InterScanMSS
      # Imported from p5-Sisimail/lib/Sisimai/MTA/InterScanMSS.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :from     => %r/InterScan MSS/,
          :received => %r/[ ][(]InterScanMSS[)][ ]with[ ]/,
          :subject  => [
            'Mail could not be delivered',
            # メッセージを配信できません。
            '=?iso-2022-jp?B?GyRCJWElQyU7ITwlOCRyR1s/LiRHJC0kXiQ7JHMhIxsoQg==?=',
            # メール配信に失敗しました
            '=?iso-2022-jp?B?GyRCJWEhPCVrR1s/LiRLPDpHVCQ3JF4kNyQ/GyhCDQo=?=',
          ],
        }
        Re1 = {
          :begin  => %r|\AContent-type: text/plain|,
          :rfc822 => %r|\AContent-type: message/rfc822|,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        Indicators = Sisimai::MTA.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'Trend Micro InterScan Messaging Security Suite'; end
        def smtpagent;   return 'InterScanMSS'; end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from InterScanMSS
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
          match += 1 if mhead['from'] =~ Re0[:from]
          match += 1 if Re0[:subject].find { |a| mhead['subject'] == a }
          return nil if match == 0

          dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
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
              if cv = e.match(/\A([-0-9A-Za-z]+?)[:][ ]*.+\z/)
                # Get required headers only
                lhs = cv[1].downcase
                previousfn = ''
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

              # Sent <<< RCPT TO:<kijitora@example.co.jp>
              # Received >>> 550 5.1.1 <kijitora@example.co.jp>... user unknown
              v = dscontents[-1]

              if cv = e.match(/\A.+[<>]{3}[ \t]+.+[<]([^ ]+[@][^ ]+)[>]\z/) ||
                 cv = e.match(/\A.+[<>]{3}[ \t]+.+[<]([^ ]+[@][^ ]+)[>]/)
                # Sent <<< RCPT TO:<kijitora@example.co.jp>
                # Received >>> 550 5.1.1 <kijitora@example.co.jp>... user unknown
                cr = cv[1]
                if v['recipient'] && cr != v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cr
                recipients = dscontents.size
              end

              if cv = e.match(/\ASent[ ]+[<]{3}[ ]+([A-Z]{4})[ ]/)
                # Sent <<< RCPT TO:<kijitora@example.co.jp>
                v['command'] = cv[1]

              elsif cv = e.match(/\AReceived[ ]+[>]{3}[ ]+(\d{3}[ ]+.+)\z/)
                # Received >>> 550 5.1.1 <kijitora@example.co.jp>... user unknown
                v['diagnosis'] = cv[1]
              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['agent'] = Sisimai::MTA::InterScanMSS.smtpagent
            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              %w|lhost rhost|.each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
            e['status'] = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['spec']   = e['reason'] == 'mailererror' ? 'X-UNIX' : 'SMTP'
            e['action'] = 'failed' if e['status'] =~ /\A[45]/
            e.each_key { |a| e[a] ||= '' }
          end

          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

