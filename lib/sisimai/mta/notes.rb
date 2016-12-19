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
          userunknown: %r{(?:
             User[ ]not[ ]listed[ ]in[ ]public[ ]Name[ ][&][ ]Address[ ]Book
            |ディレクトリのリストにありません
            )
          }x,
          networkerror: %r/Message has exceeded maximum hop count/,
        }
        Indicators = Sisimai::MTA.INDICATORS

        def description; return 'Lotus Notes'; end
        def smtpagent;   return Sisimai::MTA.smtpagent(self); end
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

          dscontents = [Sisimai::MTA.DELIVERYSTATUS]
          hasdivided = mbody.split("\n")
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
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
                readcursor |= Indicators[:deliverystatus]
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
              if e.empty?
                blanklines += 1
                break if blanklines > 1
                next
              end
              rfc822list << e

            else
              # Before "message/rfc822"
              next if readcursor & Indicators[:deliverystatus] == 0

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
            rfc822list.each do |e|
              if cv = e.match(/^To:[ ]*(.+)$/m)
                v['recipient'] = Sisimai::Address.s3s4(cv[1])
                recipients += 1 if v['recipient'].size > 0
                break
              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['agent']     = Sisimai::MTA::Notes.smtpagent
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
            e['recipient'] = Sisimai::Address.s3s4(e['recipient'])

            ReFailure.each_key do |r|
              # Check each regular expression of Notes error messages
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r.to_s
              pseudostatus = Sisimai::SMTP::Status.code(r.to_s)
              e['status'] = pseudostatus if pseudostatus.size > 0
              break
            end
            e.each_key { |a| e[a] ||= '' }
          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end
