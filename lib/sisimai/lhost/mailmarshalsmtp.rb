module Sisimai::Lhost
  # Sisimai::Lhost::MailMarshalSMTP parses a bounce email which created by Trustwave Secure Email
  # Gateway: formerly MailMarshal SMTP. Methods in the module are called from only Sisimai::Message.
  module MailMarshalSMTP
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++']
      StartingOf = {
        message: ['Your message:'],
        error:   ['Could not be delivered because of'],
        rcpts:   ['The following recipients were affected:'],
      }.freeze

      # Parse bounce messages from MailMarshalSMTP
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        return nil unless mhead['subject'].start_with?('Undeliverable Mail: "')

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        endoferror = false  # (Boolean) Flag for the end of error message
        regularexp = nil
        q = Sisimai::RFC2045.boundary(mhead['content-type'], 1); Boundaries << q if q
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email
          # to the previous line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e == StartingOf[:message][0]
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0

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

          if e.start_with?('    ') && e.index('@') > 1
            # The following recipients were affected:
            #    dummyuser@blabla.xxxxxxxxxxxx.com
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = e[4, e.size]
            recipients += 1
          else
            # Get error message lines
            if e == StartingOf[:error][0]
              # Could not be delivered because of
              #
              # 550 5.1.1 User unknown
              v['diagnosis'] = e

            elsif !v['diagnosis'].to_s.empty? && endoferror == false
              # Append error messages
              endoferror = true if e.start_with?(StartingOf[:rcpts][0])
              next if endoferror
              v['diagnosis'] << ' ' << e
            else
              # Additional Information
              # ======================
              # Original Sender:    <originalsender@example.com>
              # Sender-MTA:         <10.11.12.13>
              # Remote-MTA:         <10.0.0.1>
              # Reporting-MTA:      <relay.xxxxxxxxxxxx.com>
              # MessageName:        <B549996730000.000000000001.0003.mml>
              # Last-Attempt-Date:  <16:21:07 seg, 22 Dezembro 2014>
              p1 = e.index('<')
              p2 = e.index('>')
              if e.start_with?('Original Sender: ')
                # Original Sender:    <originalsender@example.com>
                # Use this line instead of "From" header of the original message.
                emailparts[1] << ('From: ' << e[p1 + 1, p2 - p1 - 1] << "\n")

              elsif e.start_with?('Sender-MTA: ')
                # Sender-MTA:         <10.11.12.13>
                v['lhost'] = e[p1 + 1, p2 - p1 - 1]

              elsif e.start_with?('Reporting-MTA: ')
                # Reporting-MTA:      <relay.xxxxxxxxxxxx.com>
                v['rhost'] = e[p1 + 1, p2 - p1 - 1]

              elsif e.include?(' From:') || e.include?(' Subject:')
                #    From:    originalsender@example.com
                #    Subject: ...
                p1 = e.index(' From:') || e.index(' Subject:')
                p2 = e.index(':')
                cf = e[p1 + 1, p2 - p1 - 1]
                cv = Sisimai::String.sweep(e[p2 + 1, e.size])
                emailparts[1] << sprintf("%s: %s\n", cf, cv)
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each { |e| e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) }
        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Trustwave Secure Email Gateway'; end
    end
  end
end

