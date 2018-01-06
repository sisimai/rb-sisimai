module Sisimai::Bite::Email
  # Sisimai::Bite::Email::EZweb parses a bounce email which created by au EZweb.
  # Methods in the module are called from only Sisimai::Message.
  module EZweb
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/EZweb.pm
      require 'sisimai/bite/email'

      Re0 = {
        :'from'       => %r/[<]?(?>postmaster[@]ezweb[.]ne[.]jp)[>]?/i,
        :'subject'    => %r/\AMail System Error - Returned Mail\z/,
        :'received'   => %r/\Afrom[ ](?:.+[.])?ezweb[.]ne[.]jp[ ]/,
        :'message-id' => %r/[@].+[.]ezweb[.]ne[.]jp[>]\z/,
      }.freeze
      Re1 = {
        :begin  => %r{\A(?:
             The[ ]user[(]s[)][ ]
            |Your[ ]message[ ]
            |Each[ ]of[ ]the[ ]following
            |[<][^ ]+[@][^ ]+[>]\z
            )
        }x,
        :rfc822   => %r#\A(?:[-]{50}|Content-Type:[ ]*message/rfc822)#,
        :boundary => %r/\A__SISIMAI_PSEUDO_BOUNDARY__\z/,
        :endof    => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
      }.freeze
      ReFailure = {
        # notaccept: [ %r/The following recipients did not receive this message:/ ],
        mailboxfull: [
          %r/The user[(]s[)] account is temporarily over quota/,
        ],
        suspend: [
          # http://www.naruhodo-au.kddi.com/qa3429203.html
          # The recipient may be unpaid user...?
          %r/The user[(]s[)] account is disabled[.]/,
          %r/The user[(]s[)] account is temporarily limited[.]/,
        ],
        expired: [
          # Your message was not delivered within 0 days and 1 hours.
          # Remote host is not responding.
          %r/Your message was not delivered within /,
        ],
        onhold: [
          %r/Each of the following recipients was rejected by a remote mail server/,
        ],
      }.freeze
      Indicators = Sisimai::Bite::Email.INDICATORS

      def description; return 'au EZweb: http://www.au.kddi.com/mobile/'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return ['X-SPASIGN']; end
      def pattern;     return Re0; end

      # Parse bounce messages from au EZweb
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
        return nil unless mhead
        return nil unless mbody

        match  = 0
        match += 1 if mhead['from']    =~ Re0[:from]
        match += 1 if mhead['subject'] =~ Re0[:subject]
        match += 1 if mhead['received'].find { |a| a =~ Re0[:received] }
        if mhead['message-id']
          match += 1 if mhead['message-id'] =~ Re0[:'message-id']
        end
        return nil if match < 2

        require 'sisimai/string'
        require 'sisimai/address'
        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        rxboundary = %r/\A__SISIMAI_PSEUDO_BOUNDARY__\z/
        v = nil

        if mhead['content-type']
          # Get the boundary string and set regular expression for matching with
          # the boundary string.
          require 'sisimai/mime'
          b0 = Sisimai::MIME.boundary(mhead['content-type'], 1)
          if b0.size > 0
            # Convert to regular expression
            rxboundary = Regexp.new('\A' + Regexp.escape(b0) + '\z')
          end
        end
        rxmessages = []
        ReFailure.each_key { |a| rxmessages.concat(ReFailure[a]) }

        hasdivided.each do |e|
          if readcursor.zero?
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e =~ Re1[:begin]
          end

          if (readcursor & Indicators[:'message-rfc822']).zero?
            # Beginning of the original message part
            if e =~ Re1[:rfc822] || e =~ rxboundary
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
            next if (readcursor & Indicators[:deliverystatus]).zero?
            next if e.empty?

            # The user(s) account is disabled.
            #
            # <***@ezweb.ne.jp>: 550 user unknown (in reply to RCPT TO command)
            #
            #  -- OR --
            # Each of the following recipients was rejected by a remote
            # mail server.
            #
            #    Recipient: <******@ezweb.ne.jp>
            #    >>> RCPT TO:<******@ezweb.ne.jp>
            #    <<< 550 <******@ezweb.ne.jp>: User unknown
            v = dscontents[-1]

            if cv = e.match(/\A[<]([^ ]+[@][^ ]+)[>]\z/) ||
                    e.match(/\A[<]([^ ]+[@][^ ]+)[>]:?(.*)\z/) ||
                    e.match(/\A[ \t]+Recipient: [<]([^ ]+[@][^ ]+)[>]/)

              if v['recipient']
                # There are multiple recipient addresses in the message body.
                push dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end

              r = Sisimai::Address.s3s4(cv[1])
              if Sisimai::RFC5322.is_emailaddress(r)
                v['recipient'] = r
                recipients += 1
              end

            elsif cv = e.match(/\A[Ss]tatus:[ ]*(\d[.]\d+[.]\d+)/)
              # Status: 5.1.1
              # Status:5.2.0
              # Status: 5.1.0 (permanent failure)
              v['status'] = cv[1]

            elsif cv = e.match(/\A[Aa]ction:[ ]*(.+)\z/)
              # Action: failed
              v['action'] = cv[1].downcase

            elsif cv = e.match(/\A[Rr]emote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/)
              # Remote-MTA: DNS; mx.example.jp
              v['rhost'] = cv[1].downcase

            elsif cv = e.match(/\A[Ll]ast-[Aa]ttempt-[Dd]ate:[ ]*(.+)\z/)
              # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
              v['date'] = cv[1]

            else
              next if Sisimai::String.is_8bit(e)
              if cv = e.match(/\A[ \t]+[>]{3}[ \t]+([A-Z]{4})/)
                #    >>> RCPT TO:<******@ezweb.ne.jp>
                v['command'] = cv[1]

              else
                # Check error message
                if rxmessages.find { |a| e =~ a }
                  # Check with regular expressions of each error
                  v['diagnosis'] ||= ''
                  v['diagnosis']  += ' ' + e

                else
                  # >>> 550
                  v['alterrors'] ||= ''
                  v['alterrors']  += ' ' + e
                end
              end
            end
          end
        end
        return nil if recipients.zero?

        dscontents.map do |e|
          if e['alterrors'] && e['alterrors'].size > 0
            # Copy alternative error message
            e['diagnosis'] ||= e['alterrors']
            if e['diagnosis'] =~ /\A[-]+/ || e['diagnosis'].end_with?('__')
              # Override the value of diagnostic code message
              e['diagnosis'] = e['alterrors'] if e['alterrors'].size > 0
            end
            e.delete('alterrors')
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          if mhead['x-spasign'] && mhead['x-spasign'] == 'NG'
            # Content-Type: text/plain; ..., X-SPASIGN: NG (spamghetti, au by EZweb)
            # Filtered recipient returns message that include 'X-SPASIGN' header
            e['reason'] = 'filtered'

          else
            if e['command'] == 'RCPT'
              # set "userunknown" when the remote server rejected after RCPT
              # command.
              e['reason'] = 'userunknown'
            else
              # SMTP command is not RCPT
              catch :SESSION do
                ReFailure.each_key do |r|
                  # Verify each regular expression of session errors
                  ReFailure[r].each do |rr|
                    # Check each regular expression
                    next unless e['diagnosis'] =~ rr
                    e['reason'] = r.to_s
                    throw :SESSION
                  end
                end
              end

            end
          end

          unless e['reason']
            # The value of "reason" is not set yet.
            unless e['recipient'].end_with?('@ezweb.ne.jp')
              # Deal as "userunknown" when the domain part of the recipient
              # is "ezweb.ne.jp".
              e['reason'] = 'userunknown'
            end
          end
          e['agent'] = self.smtpagent
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

