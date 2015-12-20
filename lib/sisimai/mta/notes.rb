module Sisimai
  module MTA
    # Sisimai::MTA::Notes parses a bounce email which created by Lotus Notes
    # Server. Methods in the module are called from only Sisimai::Message.
    module Notes
      # Imported from p5-Sisimail/lib/Sisimai/MTA/Notes.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :'subject' => %r/\AUndeliverable message/,
        }
        Re1 = {
          :begin  => %r/\A[-]+[ ]+Failure Reasons[ ]+[-]+\z/,
          :rfc822 => %r/^[-]+[ ]+Returned Message[ ]+[-]+$/,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReFailure = {
          'userunknown' => %r{(?:
             User[ ]not[ ]listed[ ]in[ ]public[ ]Name[ ][&][ ]Address[ ]Book
            |ディレクトリのリストにありません
            )
          }x,
          'networkerror' => %r/Message has exceeded maximum hop count/,
        }
        Indicators = Sisimai::MTA.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'Lotus Notes'; end
        def smtpagent;   return 'Notes'; end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from Lotus Notes
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

          dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          characters = ''     # (String) Character set name of the bounce mail
          removedmsg = 'MULTIBYTE CHARACTERS HAVE BEEN REMOVED'
          encodedmsg = ''
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

            if characters.empty?
              # Get character set name
              if cv = mhead['content-type'].match(/\A.+;[ ]*charset=(.+)\z/)
                # Content-Type: text/plain; charset=ISO-2022-JP
                characters = cv[1].downcase
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

              # ------- Failure Reasons  --------
              # 
              # User not listed in public Name & Address Book
              # kijitora@notes.example.jp
              #
              # ------- Returned Message --------
              v = dscontents[-1]
              if e =~ /\A[^ ]+[@][^ ]+/
                # kijitora@notes.example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] ||= e
                recipients += 1

              else
                next if e =~ /\A\z/
                next if e =~ /\A[-]+/

                if e =~ /[^\x20-\x7e]/
                  # Error message is not ISO-8859-1
                  if characters.size > 0
                    # Try to convert string
                    begin
                      encodedmsg = e.encode('UTF-8', characters)
                    rescue
                      # Failed to convert
                      encodedmsg = removedmsg
                    end
                  else
                    # No character set in Content-Type header
                    encodedmsg = removedmsg
                  end
                  v['diagnosis'] ||= ''
                  v['diagnosis']  += encodedmsg
                else
                  # Error message does not include multi-byte character
                  v['diagnosis'] ||= ''
                  v['diagnosis']  += e
                end
              end
            end
          end

          if recipients == 0
            # Fallback: Get the recpient address from RFC822 part
            if cv = rfc822part.match(/^To:[ ]*(.+)$/m)
              v['recipient'] = Sisimai::Address.s3s4(cv[1])
              recipients += 1 if v['recipient'].size > 0
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['agent'] = Sisimai::MTA::Notes.smtpagent

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r0 = mhead['received']
              ['lhost', 'rhost'].each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r0[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r0[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
            e['recipient'] = Sisimai::Address.s3s4(e['recipient'])

            ReFailure.each_key do |r|
              # Check each regular expression of Notes error messages
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r
              pseudostatus = Sisimai::SMTP::Status.code(r)
              e['status'] = pseudostatus if pseudostatus.size > 0
              break
            end
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
