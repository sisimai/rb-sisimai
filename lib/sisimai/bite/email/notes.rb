module Sisimai::Bite::Email
  # Sisimai::Bite::::Email::Notes parses a bounce email which created by Lotus
  # Notes Server. Methods in the module are called from only Sisimai::Message.
  module Notes
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Notes.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['------- Failure Reasons '],
        rfc822:  ['------- Returned Message '],
      }.freeze
      MessagesOf = {
        userunknown: [
          'User not listed in public Name & Address Book',
          'ディレクトリのリストにありません',
        ],
        networkerror: ['Message has exceeded maximum hop count'],
      }.freeze

      def description; return 'Lotus Notes'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Lotus Notes
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
        return nil unless mhead['subject'].start_with?('Undeliverable message')

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        characters = ''     # (String) Character set name of the bounce mail
        removedmsg = 'MULTIBYTE CHARACTERS HAVE BEEN REMOVED'
        encodedmsg = ''
        v = nil

        while e = hasdivided.shift do
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e.start_with?(StartingOf[:message][0])
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e.start_with?(StartingOf[:rfc822][0])
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
            next if (readcursor & Indicators[:deliverystatus]) == 0

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
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] ||= e
              recipients += 1
            else
              next if e.empty?
              next if e.start_with?('-')

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
                v['diagnosis'] << encodedmsg
              else
                # Error message does not include multi-byte character
                v['diagnosis'] ||= ''
                v['diagnosis'] << e
              end
            end
          end
        end

        unless recipients > 0
          # Fallback: Get the recpient address from RFC822 part
          rfc822list.each do |e|
            next unless cv = e.match(/^To:[ ]*(.+)$/m)

            v['recipient'] = Sisimai::Address.s3s4(cv[1])
            recipients += 1 unless v['recipient'].empty?
            break
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['recipient'] = Sisimai::Address.s3s4(e['recipient'])

          MessagesOf.each_key do |r|
            # Check each regular expression of Notes error messages
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r.to_s
            pseudostatus = Sisimai::SMTP::Status.code(r.to_s)
            e['status'] = pseudostatus unless pseudostatus.empty?
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

