module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Courier parses a bounce email which created by Courier
  # MTA. Methods in the module are called from only Sisimai::Message.
  module Courier
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Courier.pm
      require 'sisimai/bite/email'

      # http://www.courier-mta.org/courierdsn.html
      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        # courier/module.dsn/dsn*.txt
        message: ['DELAYS IN DELIVERING YOUR MESSAGE', 'UNDELIVERABLE MAIL'],
        rfc822:  ['Content-Type: message/rfc822', 'Content-Type: text/rfc822-headers'],
      }.freeze

      MessagesOf = {
        # courier/module.esmtp/esmtpclient.c:526| hard_error(del, ctf, "No such domain.");
        hostunknown: ['No such domain.'],
        # courier/module.esmtp/esmtpclient.c:531| hard_error(del, ctf,
        # courier/module.esmtp/esmtpclient.c:532|  "This domain's DNS violates RFC 1035.");
        systemerror: ["This domain's DNS violates RFC 1035."],
        # courier/module.esmtp/esmtpclient.c:535| soft_error(del, ctf, "DNS lookup failed.");
        networkerror: ['DNS lookup failed.'],
      }.freeze

      def description; return 'Courier MTA'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Courier MTA
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
        match  = 0
        match += 1 if mhead['from'].include?('Courier mail server at ')
        match += 1 if mhead['subject'] =~ /(?:NOTICE: mail delivery status[.]|WARNING: delayed mail[.])/
        if mhead['message-id']
          # Message-ID: <courier.4D025E3A.00001792@5jo.example.org>
          match += 1 if mhead['message-id'] =~ /\A[<]courier[.][0-9A-F]+[.]/
        end
        return nil unless match > 0

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        havepassed = ['']
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        commandtxt = ''     # (String) SMTP Command name begin with the string '>>>'
        v = nil

        while e = hasdivided.shift do
          # Save the current line for the next loop
          havepassed << e
          p = havepassed[-2]

          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            if e.include?(StartingOf[:message][0]) || e.include?(StartingOf[:message][1])
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part(message/rfc822)
            if e.start_with?(StartingOf[:rfc822][0], StartingOf[:rfc822][1])
              readcursor |= Indicators[:'message-rfc822']
              next
            end
          end

          if readcursor & Indicators[:'message-rfc822'] > 0
            # message/rfc822 OR text/rfc822-headers part
            if e.empty?
              blanklines += 1
              break if blanklines > 1
              next
            end
            rfc822list << e
          else
            # message/delivery-status part
            next if (readcursor & Indicators[:deliverystatus]) == 0
            next if e.empty?

            if f = Sisimai::RFC1894.match(e)
              # "e" matched with any field defined in RFC3464
              o = Sisimai::RFC1894.field(e) || next
              v = dscontents[-1]

              if o[-1] == 'addr'
                # Final-Recipient: rfc822; kijitora@example.jp
                # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                if o[0] == 'final-recipient'
                  # Final-Recipient: rfc822; kijitora@example.jp
                  if v['recipient']
                    # There are multiple recipient addresses in the message body.
                    dscontents << Sisimai::Bite.DELIVERYSTATUS
                    v = dscontents[-1]
                  end
                  v['recipient'] = o[2]
                  recipients += 1
                else
                  # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                  v['alias'] = o[2]
                end
              elsif o[-1] == 'code'
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                v['spec'] = o[1]
                v['diagnosis'] = o[2]
              else
                # Other DSN fields defined in RFC3464
                next unless fieldtable.key?(o[0].to_sym)
                v[fieldtable[o[0].to_sym]] = o[2]

                next unless f == 1
                permessage[fieldtable[o[0].to_sym]] = o[2]
              end
            else
              # The line does not begin with a DSN field defined in RFC3464
              if cv = e.match(/\A[>]{3}[ ]+([A-Z]{4})[ ]?/)
                # Your message to the following recipients cannot be delivered:
                #
                # <kijitora@example.co.jp>:
                #    mx.example.co.jp [74.207.247.95]:
                # >>> RCPT TO:<kijitora@example.co.jp>
                # <<< 550 5.1.1 <kijitora@example.co.jp>... User Unknown
                #
                next unless commandtxt.empty?
                commandtxt = cv[1]
              else
                if p.start_with?('Diagnostic-Code:') && cv = e.match(/\A[ \t]+(.+)\z/)
                  # Continued line of the value of Diagnostic-Code header
                  v['diagnosis'] << ' ' << cv[1]
                  havepassed[-1] = 'Diagnostic-Code: ' << e
                end
              end
            end
          end # End of message/delivery-status
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          MessagesOf.each_key do |r|
            # Verify each regular expression of session errors
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r.to_s
            break
          end

          e['agent']     = self.smtpagent
          e['command'] ||= commandtxt || ''
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

