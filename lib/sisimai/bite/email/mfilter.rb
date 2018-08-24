module Sisimai::Bite::Email
  # Sisimai::Bite::Email::mFILTER parses a bounce email which created by
  # Digital Arts m-FILTER.
  # Methods in the module are called from only Sisimai::Message.
  module MFILTER
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/mFILTER.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        error:   ['-------server message'],
        command: ['-------SMTP command'],
        rfc822:  ['-------original message', '--------original mail info'],
      }.freeze
      MarkingsOf = { message: %r/\A[^ ]+[@][^ ]+[.][a-zA-Z]+\z/ }.freeze

      def description; return 'Digital Arts m-FILTER'; end
      def smtpagent;   return 'Email::mFILTER'; end
      def headerlist;  return ['X-Mailer']; end

      # Parse bounce messages from Digital Arts m-FILTER
      # @param         [Hash] mhead       Message headers of a bounce email
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
        # :'from'     => %r/\AMailer Daemon [<]MAILER-DAEMON[@]/,
        return nil unless mhead['x-mailer'].to_s == 'm-FILTER'
        return nil unless mhead['subject'] == 'failure notice'

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        markingset = { 'diagnosis' => false, 'command' => false }
        v = nil

        while e = hasdivided.shift do
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e =~ MarkingsOf[:message]
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e.start_with?(StartingOf[:rfc822][0], StartingOf[:rfc822][1])
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
            next if (readcursor & Indicators[:deliverystatus]) == 0
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
                dscontents << Sisimai::Bite.DELIVERYSTATUS
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
              if e == StartingOf[:error][0]
                # -------server message
                markingset['diagnosis'] = true

              elsif e == StartingOf[:command][0]
                # -------SMTP command
                markingset['command'] = true
              else
                # 550 5.1.1 unknown user <kijitora@example.jp>
                next if e.start_with?('-')
                next if v['diagnosis']
                v['diagnosis'] = e
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          unless mhead['received'].empty?
            # Get localhost and remote host name from Received header.
            rheads = mhead['received']
            rhosts = Sisimai::RFC5322.received(rheads[-1])

            e['lhost'] ||= Sisimai::RFC5322.received(rheads[0]).shift
            while ee = rhosts.shift do
              # Avoid "... by m-FILTER"
              next unless ee.include?('.')
              e['rhost'] = ee
            end
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['agent']     = self.smtpagent
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

