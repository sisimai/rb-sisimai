module Sisimai
  module MTA
    # Sisimai::MTA::MailFoundry parses a bounce email which created by MailFoundry.
    # Methods in the module are called from only Sisimai::Message.
    module MailFoundry
      # Imported from p5-Sisimail/lib/Sisimai/MTA/MailFoundry.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :subject  => %r/\AMessage delivery has failed\z/,
          :received => %r/[(]MAILFOUNDRY[)] id /,
        }
        Re1 = {
          :begin  => %r/\AThis is a MIME encoded message\z/,
          :error  => %r/\ADelivery failed for the following reason:\z/,
          :rfc822 => %r|\AContent-Type: message/rfc822\z|,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        Indicators = Sisimai::MTA.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'MailFoundry'; end
        def smtpagent;   return 'MailFoundry'; end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from MailFoundry
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
          return nil unless mhead['subject'] =~ Re0[:subject]
          return nil unless mhead['received'].find { |a| a =~ Re0[:received] }

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

              elsif e =~ /\A\s+/
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

              # Unable to deliver message to: <kijitora@example.org>
              # Delivery failed for the following reason:
              # Server mx22.example.org[192.0.2.222] failed with: 550 <kijitora@example.org> No such user here
              #
              # This has been a permanent failure.  No further delivery attempts will be made.
              v = dscontents[-1]

              if cv = e.match(/\AUnable to deliver message to: [<]([^ ]+[@][^ ]+)[>]\z/)
                # Unable to deliver message to: <kijitora@example.org>
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients =+ 1 

              else
                # Error message
                if e =~ Re1[:error]
                  # Delivery failed for the following reason:
                  v['diagnosis'] = e

                else
                  # Detect error message
                  next if e.empty?
                  next if v['diagnosis'].nil? || v['diagnosis'].empty?
                  next if e =~ /\A[-]+/

                  if e =~ /\AThis has been a permanent failure/
                    # This has been a permanent failure.  No further delivery attempts will be made.
                    v['softbounce'] = 0

                  else
                    # Server mx22.example.org[192.0.2.222] failed with: 550 <kijitora@example.org> No such user here
                    v['diagnosis'] ||= ''
                    v['diagnosis']  += ' ' + e
                  end
                end
              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['agent'] = Sisimai::MTA::MailFoundry.smtpagent

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              ['lhost', 'rhost'].each { |a| e[a] ||= '' }
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

