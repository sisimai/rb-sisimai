module Sisimai
  module MTA
    # Sisimai::MTA::mFILTER parses a bounce email which created by Digital Arts
    # m-FILTER. Methods in the module are called from only Sisimai::Message.
    module MFILTER
      # Imported from p5-Sisimail/lib/Sisimai/MTA/mFILTER.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :'from'     => %r/\AMailer Daemon [<]MAILER-DAEMON[@]/,
          :'subject'  => %r/\Afailure notice\z/,
          :'x-mailer' => %r/\Am-FILTER\z/,
        }
        Re1 = {
          :begin   => %r/\A[^ ]+[@][^ ]+[.][a-zA-Z]+\z/,
          :error   => %r/\A-------server message\z/,
          :command => %r/\A-------SMTP command\z/,
          :rfc822  => %r/\A-------original (?:message|mail info)\z/,
          :endof   => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        Indicators = Sisimai::MTA.INDICATORS

        def description; return 'Digital Arts m-FILTER'; end
        def smtpagent;   return 'm-FILTER'; end
        def headerlist;  return ['X-Mailer']; end
        def pattern;     return Re0; end

        # Parse bounce messages from Digital Arts m-FILTER
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
          return nil unless mhead['x-mailer']
          return nil unless mhead['x-mailer'] =~ Re0[:'x-mailer']
          return nil unless mhead['subject']  =~ Re0[:'subject']

          dscontents = [Sisimai::MTA.DELIVERYSTATUS]
          hasdivided = mbody.split("\n")
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          markingset = { 'diagnosis' => false, 'command' => false }
          v = nil

          hasdivided.each do |e|
            if readcursor == 0
              # Beginning of the bounce message or delivery status part
              readcursor |= Indicators[:deliverystatus] if e =~ Re1[:begin]
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
              next if readcursor & Indicators[:deliverystatus] == 0
              next if e.empty?

              # このメールは「m-FILTER」が自動的に生成して送信しています。
              # メールサーバーとの通信中、下記の理由により
              # このメールは送信できませんでした。
              #
              # 以下のメールアドレスへの送信に失敗しました。
              # kijitora@example.jp
              #
              #
              # -------server message
              # 550 5.1.1 unknown user <kijitora@example.jp>
              #
              # -------SMTP command
              # DATA
              #
              # -------original message
              v = dscontents[-1]

              if cv = e.match(/\A([^ ]+[@][^ ]+)\z/)
                # 以下のメールアドレスへの送信に失敗しました。
                # kijitora@example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              elsif e =~ /\A[A-Z]{4}/
                # -------SMTP command
                # DATA
                next if v['command']
                v['command'] = e if markingset['command']

              else
                # Get error message and SMTP command
                if e =~ Re1[:error]
                  # -------server message
                  markingset['diagnosis'] = true

                elsif e =~ Re1[:command]
                  # -------SMTP command
                  markingset['command'] = true

                else
                  # 550 5.1.1 unknown user <kijitora@example.jp>
                  next if e =~ /\A[-]+/
                  next if v['diagnosis']
                  v['diagnosis'] = e
                end
              end
            end
          end

          return nil if recipients == 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            e['agent'] = Sisimai::MTA::MFILTER.smtpagent

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              rheads = mhead['received']
              rhosts = Sisimai::RFC5322.received(rheads[-1])

              e['lhost'] ||= Sisimai::RFC5322.received(rheads[0]).shift
              rhosts.each do |ee|
                # Avoid "... by m-FILTER"
                next unless ee =~ /[.]/
                e['rhost'] = ee
              end
            end

            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
            e['status'] = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['spec']   = e['reason'] == 'mailererror' ? 'X-UNIX' : 'SMTP'
            e['action'] = 'failed' if e['status'] =~ /\A[45]/
            e.each_key { |a| e[a] ||= '' }
          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

