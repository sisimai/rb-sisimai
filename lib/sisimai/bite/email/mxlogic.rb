module Sisimai::Bite::Email
  # Sisimai::Bite::Email::MXLogic parses a bounce email which created by
  # McAfee SaaS (formerly MX Logic).
  # Methods in the module are called from only Sisimai::Message.
  module MXLogic
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/MXLogic.pm
      # Based on Sisimai::Bite::Email::Exim
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['This message was created automatically by mail delivery software.'],
        rfc822:  ['Included is a copy of the message header:'],
      }.freeze

      ReCommands = [
        %r/SMTP error from remote (?:mail server|mailer) after ([A-Za-z]{4})/,
        %r/SMTP error from remote (?:mail server|mailer) after end of ([A-Za-z]{4})/,
      ].freeze
      MessagesOf = {
        # find exim/ -type f -exec grep 'message = US' {} /dev/null \;
        # route.c:1158|  DEBUG(D_uid) debug_printf("getpwnam() returned NULL (user not found)\n");
        userunknown: ['user not found'],
        # transports/smtp.c:3524|  addr->message = US"all host address lookups failed permanently";
        # routers/dnslookup.c:331|  addr->message = US"all relevant MX records point to non-existent hosts";
        # route.c:1826|  uschar *message = US"Unrouteable address";
        hostunknown: [
          'all host address lookups failed permanently',
          'all relevant MX records point to non-existent hosts',
          'Unrouteable address',
        ],
        # transports/appendfile.c:2567|  addr->user_message = US"mailbox is full";
        # transports/appendfile.c:3049|  addr->message = string_sprintf("mailbox is full "
        # transports/appendfile.c:3050|  "(quota exceeded while writing to file %s)", filename);
        mailboxfull: ['mailbox is full', 'error: quota exceed'],
        # routers/dnslookup.c:328|  addr->message = US"an MX or SRV record indicated no SMTP service";
        # transports/smtp.c:3502|  addr->message = US"no host found for existing SMTP connection";
        notaccept: [
          'an MX or SRV record indicated no SMTP service',
          'no host found for existing SMTP connection',
        ],
        # parser.c:666| *errorptr = string_sprintf("%s (expected word or \"<\")", *errorptr);
        # parser.c:701| if(bracket_count++ > 5) FAILED(US"angle-brackets nested too deep");
        # parser.c:738| FAILED(US"domain missing in source-routed address");
        # parser.c:747| : string_sprintf("malformed address: %.32s may not follow %.*s",
        syntaxerror: [
          'angle-brackets nested too deep',
          'expected word or "<"',
          'domain missing in source-routed address',
          'malformed address:',
        ],
        # deliver.c:5614|  addr->message = US"delivery to file forbidden";
        # deliver.c:5624|  addr->message = US"delivery to pipe forbidden";
        # transports/pipe.c:1156|  addr->user_message = US"local delivery failed";
        systemerror: [
          'delivery to file forbidden',
          'delivery to pipe forbidden',
          'local delivery failed',
          'LMTP error after ',
        ],
        # deliver.c:5425|  new->message = US"Too many \"Received\" headers - suspected mail loop";
        contenterror: ['Too many "Received" headers'],
      }.freeze
      DelayedFor = [
        'retry timeout exceeded',
        'No action is required on your part',
        'retry time not reached for any host after a long failure period',
        'all hosts have been failing for a long time and were last tried',
        'Delay reason: ',
        'has been frozen',
        'was frozen on arrival by ',
      ].freeze

      def description; return 'McAfee SaaS'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      # X-MX-Bounce: mta/src/queue/bounce
      # X-MXL-NoteHash: ffffffffffffffff-0000000000000000000000000000000000000000
      # X-MXL-Hash: 4c9d4d411993da17-bbd4212b6c887f6c23bab7db4bd87ef5edc00758
      def headerlist;  return ['X-MXL-NoteHash', 'X-MXL-Hash', 'X-MX-Bounce']; end

      # Parse bounce messages from MXLogic
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
        # :'message-id' => %r/\A[<]mxl[~][0-9a-f]+/,
        match  = 0
        match += 1 if mhead['x-mx-bounce']
        match += 1 if mhead['x-mxl-hash']
        match += 1 if mhead['x-mxl-notehash']
        match += 1 if mhead['from'].start_with?('Mail Delivery System')
        match += 1 if mhead['subject'] =~ %r{(?:
             Mail[ ]delivery[ ]failed(:[ ]returning[ ]message[ ]to[ ]sender)?
            |Warning:[ ]message[ ].+[ ]delayed[ ]+
            |Delivery[ ]Status[ ]Notification
            )
        }x
        return nil unless match > 0

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        localhost0 = ''     # (String) Local MTA
        v = nil

        while e = hasdivided.shift do
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e == StartingOf[:message][0]
              readcursor |= Indicators[:deliverystatus]
              next
            end
          end

          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e == StartingOf[:rfc822][0]
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

            # This message was created automatically by mail delivery software.
            #
            # A message that you sent could not be delivered to one or more of its
            # recipients. This is a permanent error. The following address(es) failed:
            #
            #  kijitora@example.jp
            #    SMTP error from remote mail server after RCPT TO:<kijitora@example.jp>:
            #    host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
            v = dscontents[-1]

            if cv = e.match(/\A[ \t]*[<]([^ ]+[@][^ ]+)[>]:(.+)\z/)
              # A message that you have sent could not be delivered to one or more
              # recipients.  This is a permanent error.  The following address failed:
              #
              #  <kijitora@example.co.jp>: 550 5.1.1 ...
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              v['diagnosis'] = cv[2]
              recipients += 1

            elsif dscontents.size == recipients
              # Error message
              next if e.empty?
              v['diagnosis'] << e + ' '
            end
          end
        end
        return nil unless recipients > 0

        unless mhead['received'].empty?
          # Get the name of local MTA
          # Received: from marutamachi.example.org (c192128.example.net [192.0.2.128])
          if cv = mhead['received'][-1].match(/from[ ]([^ ]+) /) then localhost0 = cv[1] end
        end

        dscontents.each do |e|
          e['agent'] = self.smtpagent
          e['lhost'] = localhost0
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].gsub(/[-]{2}.*\z/, ''))

          unless e['rhost']
            # Get the remote host name
            # host neko.example.jp [192.0.2.222]: 550 5.1.1 <kijitora@example.jp>... User Unknown
            if cv = e['diagnosis'].match(/host[ ]+([^ \t]+)[ ]\[.+\]:[ ]/) then e['rhost'] = cv[1] end

            unless e['rhost']
              # Get localhost and remote host name from Received header.
              e['rhost'] = Sisimai::RFC5322.received(mhead['received'][-1]).pop unless mhead['received'].empty?
            end
          end

          unless e['command']
            # Get the SMTP command name for the session
            ReCommands.each do |r|
              # Verify each regular expression of SMTP commands
              if cv = e['diagnosis'].match(r)
                e['command'] = cv[1].upcase
                break
              end
            end

            # Detect the reason of bounce
            if e['command'] == 'MAIL'
              # MAIL | Connected to 192.0.2.135 but sender was rejected.
              e['reason'] = 'rejected'

            elsif %w[HELO EHLO].index(e['command'])
              # HELO | Connected to 192.0.2.135 but my name was rejected.
              e['reason'] = 'blocked'
            else
              # Verify each regular expression of session errors
              MessagesOf.each_key do |r|
                # Check each regular expression
                next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
                e['reason'] = r.to_s
                break
              end

              unless e['reason']
                # The reason "expired"
                e['reason'] = 'expired' if DelayedFor.any? { |a| e['diagnosis'].include?(a) }
              end
            end
          end
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

