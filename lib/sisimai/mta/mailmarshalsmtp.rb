module Sisimai
  module MTA
    # Sisimai::MTA::MailMarshalSMTP parses a bounce email which created by
    # Trustwave Secure Email Gateway: formerly MailMarshal SMTP. Methods in the
    # module are called from only Sisimai::Message.
    module MailMarshalSMTP
      # Imported from p5-Sisimail/lib/Sisimai/MTA/MailMarshalSMTP.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :subject  => %r/\AUndeliverable Mail: ["]/,
        }
        Re1 = {
          :begin  => %r/\AYour message:\z/,
          :rfc822 => nil,
          :error  => %r/\ACould not be delivered because of\z/,
          :rcpts  => %r/\AThe following recipients were affected:/,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        Indicators = Sisimai::MTA.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'Trustwave Secure Email Gateway'; end
        def smtpagent;   return 'MailMarshalSMTP'; end
        def headerlist;  return ['X-Mailer']; end
        def pattern;     return Re0; end

        # Parse bounce messages from MailMarshalSMTP
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

          require 'sisimai/mime'
          dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          boundary00 = ''     # (String) Boundary string
          endoferror = false  # (Boolean) Flag for the end of error message
          regularexp = nil
          v = nil

          boundary00 = Sisimai::MIME.boundary(mhead['content-type']) || ''
          if boundary00.size > 0
            # Convert to regular expression
            regularexp = Regexp.new('\A' + Regexp.escape('--' + boundary00 + '--') + '\z')
          else
            regularexp = %r/\A[ \t]*[+]+[ \t]*\z/
          end

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
              if e =~ regularexp
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
              break if e =~ regularexp

              # Your message:
              #    From:    originalsender@example.com
              #    Subject: IIdentifica蟾ｽ驕俳
              #
              # Could not be delivered because of
              #
              # 550 5.1.1 User unknown
              #
              # The following recipients were affected:
              #    dummyuser@blabla.xxxxxxxxxxxx.com
              v = dscontents[-1]

              if cv = e.match(/\A[ ]{4}([^ ]+[@][^ ]+)\z/)
                # The following recipients were affected:
                #    dummyuser@blabla.xxxxxxxxxxxx.com
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              else
                # Get error message lines
                if e =~ Re1[:error]
                  # Could not be delivered because of
                  #
                  # 550 5.1.1 User unknown
                  v['diagnosis'] = e

                elsif v['diagnosis'] && v['diagnosis'].size > 0 && endoferror == false
                  # Append error messages
                  endoferror = true if e =~ Re1[:rcpts]
                  next if endoferror
                  v['diagnosis']  += ' ' + e

                else
                  # Additional Information
                  # ======================
                  # Original Sender:    <originalsender@example.com>
                  # Sender-MTA:         <10.11.12.13>
                  # Remote-MTA:         <10.0.0.1>
                  # Reporting-MTA:      <relay.xxxxxxxxxxxx.com>
                  # MessageName:        <B549996730000.000000000001.0003.mml>
                  # Last-Attempt-Date:  <16:21:07 seg, 22 Dezembro 2014>
                  if cv = e.match(/\AOriginal Sender:[ \t]+[<](.+)[>]\z/)
                    # Original Sender:    <originalsender@example.com>
                    # Use this line instead of "From" header of the original
                    # message.
                    rfc822part += sprintf("From: %s\n", cv[1])

                  elsif cv = e.match(/\ASender-MTA:[ \t]+[<](.+)[>]\z/)
                    # Sender-MTA:         <10.11.12.13>
                    v['lhost'] = cv[1]

                  elsif cv = e.match(/\AReporting-MTA:[ \t]+[<](.+)[>]\z/)
                    # Reporting-MTA:      <relay.xxxxxxxxxxxx.com>
                    v['rhost'] = cv[1]
                  end
                end
              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['agent'] = Sisimai::MTA::MailMarshalSMTP.smtpagent

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

