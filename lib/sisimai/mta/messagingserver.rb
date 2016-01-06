module Sisimai
  module MTA
    # Sisimai::MTA::MessagingServer parses a bounce email which created by Oracle
    # Communications Messaging Server and Sun Java System Messaging Server.
    # Methods in the module are called from only Sisimai::Message.
    module MessagingServer
      # Imported from p5-Sisimail/lib/Sisimai/MTA/MessagingServer.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :subject  => %r/\ADelivery Notification: /,
          :received => %r/[ ][(]MessagingServer[)][ ]with[ ]/,
          :boundary => %r/Boundary_[(]ID_.+[)]/,
        }
        Re1 = {
          :begin  => %r/\AThis report relates to a message you sent with the following header fields:/,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
          :rfc822 => %r!\A(?:Content-type:[ ]*message/rfc822|Return-path:[ ]*)!x,
        }
        ReFailure = {
          'hostunknown' => %r{Illegal[ ]host/domain[ ]name[ ]found}x,
        }
        Indicators = Sisimai::MTA.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'Oracle Communications Messaging Server'; end
        def smtpagent;   return 'MessagingServer'; end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from MessagingServer
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
          match += 1 if mhead['content-type'] =~ Re0[:boundary]
          match += 1 if mhead['subject']      =~ Re0[:subject]
          return nil if match == 0

          require 'sisimai/address'
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

              # --Boundary_(ID_0000000000000000000000)
              # Content-type: text/plain; charset=us-ascii
              # Content-language: en-US
              # 
              # This report relates to a message you sent with the following header fields:
              # 
              #   Message-id: <CD8C6134-C312-41D5-B083-366F7FA1D752@me.example.com>
              #   Date: Fri, 21 Nov 2014 23:34:45 +0900
              #   From: Shironeko <shironeko@me.example.com>
              #   To: kijitora@example.jp
              #   Subject: Nyaaaaaaaaaaaaaaaaaaaaaan
              # 
              # Your message cannot be delivered to the following recipients:
              # 
              #   Recipient address: kijitora@example.jp
              #   Reason: Remote SMTP server has rejected address
              #   Diagnostic code: smtp;550 5.1.1 <kijitora@example.jp>... User Unknown
              #   Remote system: dns;mx.example.jp (TCP|17.111.174.67|47323|192.0.2.225|25) (6jo.example.jp ESMTP SENDMAIL-VM)
              v = dscontents[-1]

              if cv = e.match(/\A[ \t]+Recipient address:[ \t]*([^ ]+[@][^ ]+)\z/)
                #   Recipient address: kijitora@example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = Sisimai::Address.s3s4(cv[1])
                recipients += 1

              elsif cv = e.match(/\A[ \t]+Original address:[ \t]*([^ ]+[@][^ ]+)\z/)
                #   Original address: kijitora@example.jp
                v['recipient'] = Sisimai::Address.s3s4(cv[1])

              elsif cv = e.match(/\A[ \t]+Date:[ \t]*(.+)\z/)
                #   Date: Fri, 21 Nov 2014 23:34:45 +0900
                v['date'] = cv[1]

              elsif cv = e.match(/\A[ \t]+Reason:[ \t]*(.+)\z/)
                #   Reason: Remote SMTP server has rejected address
                v['diagnosis'] = cv[1]

              elsif cv = e.match(/\A[ \t]+Diagnostic code:[ \t]*([^ ]+);(.+)\z/)
                #   Diagnostic code: smtp;550 5.1.1 <kijitora@example.jp>... User Unknown
                v['spec'] = cv[1].upcase
                v['diagnosis'] = cv[2]

              elsif cv = e.match(/\A[ \t]+Remote system:[ ]*dns;([^ ]+)[ ]*([^ ]+)[ ]*.+\z/)
                #   Remote system: dns;mx.example.jp (TCP|17.111.174.67|47323|192.0.2.225|25)
                #     (6jo.example.jp ESMTP SENDMAIL-VM)
                remotehost = cv[1]  # remote host
                sessionlog = cv[2]  # smtp session
                v['rhost'] = remotehost

                if cv = sessionlog.match(/\A[(]TCP|(.+)|\d+|(.+)|\d+[)]/)
                  # The value does not include ".", use IP address instead.
                  # (TCP|17.111.174.67|47323|192.0.2.225|25)
                  v['lhost'] = cv[1]
                  v['rhost'] = cv[2] unless remotehost =~ /[^.]+[.][^.]+/
                end

              else
                # Original-envelope-id: 0NFC009FLKOUVMA0@mr21p30im-asmtp004.me.com
                # Reporting-MTA: dns;mr21p30im-asmtp004.me.com (tcp-daemon)
                # Arrival-date: Thu, 29 Apr 2014 23:34:45 +0000 (GMT)
                # 
                # Original-recipient: rfc822;kijitora@example.jp
                # Final-recipient: rfc822;kijitora@example.jp
                # Action: failed
                # Status: 5.1.1 (Remote SMTP server has rejected address)
                # Remote-MTA: dns;mx.example.jp (TCP|17.111.174.67|47323|192.0.2.225|25)
                #  (6jo.example.jp ESMTP SENDMAIL-VM)
                # Diagnostic-code: smtp;550 5.1.1 <kijitora@example.jp>... User Unknown
                #
                if cv = e.match(/\A[Ss]tatus:[ ]*(\d[.]\d[.]\d)[ ]*[(](.+)[)]\z/)
                  # Status: 5.1.1 (Remote SMTP server has rejected address)
                  v['status'] = cv[1]
                  v['diagnosis'] ||= cv[2]

                elsif cv = e.match(/\A[Aa]rrival-[Dd]ate:[ ]*(.+)\z/)
                  # Arrival-date: Thu, 29 Apr 2014 23:34:45 +0000 (GMT)
                  v['date'] ||= cv[1]

                elsif cv = e.match(/\A[Rr]eporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
                  # Reporting-MTA: dns;mr21p30im-asmtp004.me.com (tcp-daemon)
                  localhost = cv[1]
                  v['lhost'] ||= localhost
                  v['lhost']   = localhost unless v['lhost'] =~ /[^.]+[.][^ ]+/
                end
              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['agent'] = Sisimai::MTA::MessagingServer.smtpagent

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              ['lhost', 'rhost'].each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            
            ReFailure.each_key do |r|
              # Verify each regular expression of session errors
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r
              break
            end

            if e['status'].nil? || e['status'].empty? || e['status'] =~ /\A\d[.]0[.]0\z/
              # There is no value of Status header or the value is 5.0.0, 4.0.0
              pseudostatus = Sisimai::SMTP::Status.find(e['diagnosis'])
              e['status'] = pseudostatus if pseudostatus.size > 0
            end
            e['action'] = 'failed' if e['status'] =~ /\A[45]/
            e.each_key { |a| e[a] ||= '' }
          end

          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

