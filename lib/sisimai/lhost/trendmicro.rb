module Sisimai::Lhost
  # Sisimai::Lhost::TrendMicro decodes a bounce email which created by TREND VISION ONE: Email and
  # Collaboration Security: https://www.trendmicro.com/en_us/business/products/email-and-collaboration.html
  # Methods in the module are called from only Sisimai::Message.
  module TrendMicro
    class << self
      require 'sisimai/eb'
      require 'sisimai/lhost'
      Boundaries = ['Content-Type: message/rfc822'].freeze

        # @abstract Decodes the bounce message from Trend Micro TREND VISION ONE
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        # :received => %r/[ ][(]InterScanMSS[)][ ]with[ ]/,
        match = 0
        tryto = [
          'Mail could not be delivered',
          'メッセージを配信できません。',
          'メール配信に失敗しました',
        ]
        match += 1 if mhead['from'].start_with?('"InterScan MSS"')
        match += 1 if mhead['from'].start_with?('"InterScan Notification"')
        match += 1 if tryto.any? { |a| mhead['subject'] == a }
        return nil if match == 0

        require 'sisimai/smtp/command'
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]; v = nil
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        recipients = 0      # (Integer) The number of 'Final-Recipient' header

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          next if e.empty?

          v  = dscontents[-1]
          p1 = e.index(' <<< ') || -1 # Sent <<< ...
          p2 = e.index(' >>> ') || -1 # Received >>> ...
          if e.include?('@') && e.include?(' <') && ( p1 > 1 || p2 > 1 || e.include?('Unable to deliver ') )
            # Sent <<< RCPT TO:<kijitora@example.co.jp>
            # Received >>> 550 5.1.1 <kijitora@example.co.jp>... user unknown
            # Unable to deliver message to <kijitora@neko.example.jp>
            cr = e[e.rindex('<') + 1, e.rindex('>') - e.rindex('<') - 1]

            if v["recipient"] != "" && cr != v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cr
            v['diagnosis'] = e if e.include?('Unable to deliver ')
            recipients = dscontents.size
          end

          case
          when e.start_with?('Sent <<< ')
            # Sent <<< RCPT TO:<kijitora@example.co.jp>
            v['command'] = Sisimai::SMTP::Command.find(e)

          when e.start_with?('Received >>> ')
            # Received >>> 550 5.1.1 <kijitora@example.co.jp>... user unknown
            v['diagnosis'] = e[e.index(' >>> ') + 4, e.size]
          else
            # Error message in non-English
            v['command'] = Sisimai::SMTP::Command.find(e) if e.include?(' >>> ')
            p3 = e.index(' <<< '); next if p3.nil?
            v['diagnosis'] = e[p3 + 4, e.size]
          end
        end
        return nil if recipients == 0

        dscontents.each do |e|
          e['reason'] = Sisimai::Eb::ReUSER if e['diagnosis'].include?('Unable to deliver')
        end
        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'TREND VISION ONE(Email and Collaboration Security)'; end
    end
  end
end

