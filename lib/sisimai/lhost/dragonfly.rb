module Sisimai::Lhost
  # Sisimai::Lhost::DragonFly parses a bounce email which created by DMA: DragonFly Mail Agent.
  # Methods in the module are called from only Sisimai::Message.
  module DragonFly
    class << self
      require 'sisimai/lhost'
      require 'sisimai/address'
      require 'sisimai/smtp/command'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['Original message follows.', 'Message headers follow'].freeze
      StartingOf = {
        # https://github.com/corecode/dma/blob/ffad280aa40c242aa9a2cb9ca5b1b6e8efedd17e/mail.c#L84
        message: ['This is the DragonFly Mail Agent '],
      }.freeze
      MessagesOf = {
        'expired' => [
          # https://github.com/corecode/dma/blob/master/dma.c#L370C1-L374C19
          # dma.c:370| if (gettimeofday(&now, NULL) == 0 &&
          # dma.c:371|     (now.tv_sec - st.st_mtim.tv_sec > MAX_TIMEOUT)) {
          # dma.c:372|     snprintf(errmsg, sizeof(errmsg),
          # dma.c:373|          "Could not deliver for the last %d seconds. Giving up.",
          # dma.c:374|          MAX_TIMEOUT);
          # dma.c:375|     goto bounce;
          # dma.c:376| }
          'Could not deliver for the last ',
        ],
        'hostunknown' => [
          # net.c:663| snprintf(errmsg, sizeof(errmsg), "DNS lookup failure: host %s not found", host);
          'DNS lookup failure: host ',
        ],
      }.freeze

      # Parse bounce messages from DMA: DragonFly Mail Agent
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['subject'].start_with?('Mail delivery failed')
        return nil unless mhead['received'].any? { |a| a.include?(' (DragonFly Mail Agent') }

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e.start_with?(StartingOf[:message][0])
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # This is the DragonFly Mail Agent v0.13 at df.example.jp.
          #
          # There was an error delivering your mail to <kijitora@example.com>.
          #
          # email.example.jp [192.0.2.25] did not like our RCPT TO:
          # 552 5.2.2 <kijitora@example.com>: Recipient address rejected: Mailbox full
          #
          # Original message follows.
          v = dscontents[-1]

          if e.start_with?('There was an error delivering your mail to <')
            # email.example.jp [192.0.2.25] did not like our RCPT TO:
            # 552 5.2.2 <kijitora@example.com>: Recipient address rejected: Mailbox full
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = Sisimai::Address.find(e, false)[0][:address]
            recipients += 1
          else
            # Pick the error message
            v['diagnosis'] ||= ''
            v['diagnosis'] << ' ' << e

            # Pick the remote hostname, and the SMTP command
            # net.c:500| snprintf(errmsg, sizeof(errmsg), "%s [%s] did not like our %s:\n%s",
            next unless e.include?(' did not like our ')
            next if v['rhost']

            p = e.split(' ', 3)
            v['rhost']   = if p[0].include?('.') then p[0] else p[1] end
            v['command'] = Sisimai::SMTP::Command.find(e) || ''
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          MessagesOf.each_key do |r|
            # Verify each regular expression of session errors
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r
            break
          end
        end
        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'DragonFly'; end
    end
  end
end

