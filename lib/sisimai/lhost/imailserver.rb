module Sisimai::Lhost
  # Sisimai::Lhost::IMailServer decodes a bounce email which created by Progress iMail Server
  # https://community.progress.com/s/products/imailserver.
  # Methods in the module are called from only Sisimai::Message.
  module IMailServer
    class << self
      require 'sisimai/lhost'

      Boundaries = ['Original message follows.'].freeze
      StartingOf = { error: ['Body of message generated response:'] }.freeze
      ReFailures = {
        'hostunknown'   => ['Unknown host'],
        'userunknown'   => ['Unknown user', 'Invalid final delivery userid'],
        'mailboxfull'   => ['User mailbox exceeds allowed size'],
        'virusdetected' => ['Requested action not taken: virus detected'],
        'undefined'     => ['undeliverable to'],
        'expired'       => ['Delivery failed '],
      }.freeze

      # @abstract Decodes the bounce message from Progress iMail Server
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        # X-Mailer: <SMTP32 v8.22>
        match  = 0
        match += 1 if mhead['subject'].start_with?('Undeliverable Mail ')
        match += 1 if mhead['x-mailer'].to_s.start_with?('<SMTP32 v')
        return nil unless match > 0

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.

          # Unknown user: kijitora@example.com
          #
          # Original message follows.
          v = dscontents[-1]

          p0 = e.index(': ') || -1
          if p0 > 8 && Sisimai::String.aligned(e, [': ', '@'])
            # Unknown user: kijitora@example.com
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['diagnosis'] = e
            v['recipient'] = Sisimai::Address.s3s4(e[p0 + 2, e.size])
            recipients += 1

          elsif e.start_with?('undeliverable ')
            # undeliverable to kijitora@example.com
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = Sisimai::Address.s3s4(e)
            recipients += 1
          else
            # Other error message text
            v['alterrors'] << ' ' << e if v['alterrors']
            v['alterrors'] = e if e.include?(StartingOf[:error][0])
          end
        end
        return nil unless recipients > 0

        require 'sisimai/smtp/command'
        dscontents.each do |e|
          unless e['alterrors'].to_s.empty?
            # Copy alternative error message
            e['diagnosis'] = if e['diagnosis']
                               e['alterrors'] + ' ' + e['diagnosis']
                             else
                               e['alterrors']
                             end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
            e.delete('alterrors')
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''
          e['command']   = Sisimai::SMTP::Command.find(e['diagnosis'])

          ReFailures.each_key do |r|
            # Verify each regular expression of session errors
            next unless ReFailures[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r
            break
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'IPSWITCH IMail Server'; end
    end
  end
end

