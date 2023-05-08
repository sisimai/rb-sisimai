module Sisimai::Lhost
  # Sisimai::Lhost::X4 parses a bounce email which created by some qmail clone. Methods in the module
  # are called from only Sisimai::Message.
  module X4
    class << self
      # MTA module for qmail clones
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['--- Below this line is a copy of the message.', 'Original message follows.'].freeze
      StartingOf = {
        #  qmail-remote.c:248|    if (code >= 500) {
        #  qmail-remote.c:249|      out("h"); outhost(); out(" does not like recipient.\n");
        #  qmail-remote.c:265|  if (code >= 500) quit("D"," failed on DATA command");
        #  qmail-remote.c:271|  if (code >= 500) quit("D"," failed after I sent the message");
        #
        # Characters: K,Z,D in qmail-qmqpc.c, qmail-send.c, qmail-rspawn.c
        #  K = success, Z = temporary error, D = permanent error
        error:   ['Remote host said:'],
        message: [
          'He/Her is not ',
          'unable to deliver your message to the following addresses',
          'Su mensaje no pudo ser entregado',
          'This is the machine generated message from mail service',
          'This is the mail delivery agent at',
          'Unable to deliver message to the following address',
          'Unfortunately, your mail was not delivered to the following address:',
          'Your mail message to the following address',
          'Your message to the following addresses',
          "We're sorry.",
        ],
        rhost:   ['Giving up on ', 'Connected to ', 'remote host '],
      }.freeze
      CommandSet = {
        # Error text regular expressions which defined in qmail-remote.c
        # qmail-remote.c:225|  if (smtpcode() != 220) quit("ZConnected to "," but greeting failed");
        'conn' => [' but greeting failed.'],
        # qmail-remote.c:231|  if (smtpcode() != 250) quit("ZConnected to "," but my name was rejected");
        'ehlo' => [' but my name was rejected.'],
        # qmail-remote.c:238|  if (code >= 500) quit("DConnected to "," but sender was rejected");
        # reason = rejected
        'mail' => [' but sender was rejected.'],
        # qmail-remote.c:249|  out("h"); outhost(); out(" does not like recipient.\n");
        # qmail-remote.c:253|  out("s"); outhost(); out(" does not like recipient.\n");
        # reason = userunknown
        'rcpt' => [' does not like recipient.'],
        # qmail-remote.c:265|  if (code >= 500) quit("D"," failed on DATA command");
        # qmail-remote.c:266|  if (code >= 400) quit("Z"," failed on DATA command");
        # qmail-remote.c:271|  if (code >= 500) quit("D"," failed after I sent the message");
        # qmail-remote.c:272|  if (code >= 400) quit("Z"," failed after I sent the message");
        'data' => [' failed on DATA command', ' failed after I sent the message'],
      }.freeze

      ReSMTP = {
        # Error text regular expressions which defined in qmail-remote.c
        # qmail-remote.c:225|  if (smtpcode() != 220) quit("ZConnected to "," but greeting failed");
        'conn' => %r/(?:Error:)?Connected to [^ ]+ but greeting failed[.]/,
        # qmail-remote.c:231|  if (smtpcode() != 250) quit("ZConnected to "," but my name was rejected");
        'ehlo' => %r/(?:Error:)?Connected to [^ ]+ but my name was rejected[.]/,
        # qmail-remote.c:238|  if (code >= 500) quit("DConnected to "," but sender was rejected");
        # reason = rejected
        'mail' => %r/(?:Error:)?Connected to [^ ]+ but sender was rejected[.]/,
        # qmail-remote.c:249|  out("h"); outhost(); out(" does not like recipient.\n");
        # qmail-remote.c:253|  out("s"); outhost(); out(" does not like recipient.\n");
        # reason = userunknown
        'rcpt' => %r/(?:Error:)?[^ ]+ does not like recipient[.]/,
        # qmail-remote.c:265|  if (code >= 500) quit("D"," failed on DATA command");
        # qmail-remote.c:266|  if (code >= 400) quit("Z"," failed on DATA command");
        # qmail-remote.c:271|  if (code >= 500) quit("D"," failed after I sent the message");
        # qmail-remote.c:272|  if (code >= 400) quit("Z"," failed after I sent the message");
        'data' => %r{(?:
           (?:Error:)?[^ ]+[ ]failed[ ]on[ ]DATA[ ]command[.]
          |(?:Error:)?[^ ]+[ ]failed[ ]after[ ]I[ ]sent[ ]the[ ]message[.]
          )
        }x,
      }.freeze

      # qmail-send.c:922| ... (&dline[c],"I'm not going to try again; this message has been in the queue too long.\n")) nomem();
      HasExpired = 'this message has been in the queue too long.'
      OnHoldPair = [' does not like recipient.', 'this message has been in the queue too long.'].freeze
      FailOnLDAP = {
        # qmail-ldap-1.03-20040101.patch:19817 - 19866
        'suspend'     => ['Mailaddress is administrative?le?y disabled'],   # 5.2.1
        'userunknown' => ['Sorry, no mailbox here by that name'],           # 5.1.1
        'exceedlimit' => ['The message exeeded the maximum size the user accepts'], # 5.2.3
        'systemerror' => [
            'Automatic homedir creator crashed',                # 4.3.0
            'Illegal value in LDAP attribute',                  # 5.3.5
            'LDAP attribute is not given but mandatory',        # 5.3.5
            'Timeout while performing search on LDAP server',   # 4.4.3
            'Too many results returned but needs to be unique', # 5.3.5
            'Permanent error while executing qmail-forward',    # 5.4.4
            'Temporary error in automatic homedir creation',    # 4.3.0 or 5.3.0
            'Temporary error while executing qmail-forward',    # 4.4.4
            'Temporary failure in LDAP lookup',                 # 4.4.3
            'Unable to contact LDAP server',                    # 4.4.3
            'Unable to login into LDAP server, bad credentials',# 4.4.3
        ],
      }.freeze
      MessagesOf = {
        # qmail-local.c:589|  strerr_die1x(100,"Sorry, no mailbox here by that name. (#5.1.1)");
        # qmail-remote.c:253|  out("s"); outhost(); out(" does not like recipient.\n");
        'userunknown'  => ['no mailbox here by that name', 'does not like recipient.'],
        # error_str.c:192|  X(EDQUOT,"disk quota exceeded")
        'mailboxfull'  => ['disk quota exceeded'],
        # qmail-qmtpd.c:233| ... result = "Dsorry, that message size exceeds my databytes limit (#5.3.4)";
        # qmail-smtpd.c:391| ... out("552 sorry, that message size exceeds my databytes limit (#5.3.4)\r\n"); return;
        'mesgtoobig'   => ['Message size exceeds fixed maximum message size:'],
        # qmail-remote.c:68|  Sorry, I couldn't find any host by that name. (#4.1.2)\n"); zerodie();
        # qmail-remote.c:78|  Sorry, I couldn't find any host named ");
        'hostunknown'  => ["Sorry, I couldn't find any host "],
        'systemfull'   => ['Requested action not taken: mailbox unavailable (not enough free space)'],
        'systemerror'  => [
          'bad interpreter: No such file or directory',
          'system error',
          'Unable to',
        ],
        'networkerror' => [
          "Sorry, I wasn't able to establish an SMTP connection",
          "Sorry, I couldn't find a mail exchanger or IP address",
          "Sorry. Although I'm listed as a best-preference MX or A for that host",
        ],
      }.freeze

      # Parse bounce messages from Unknown MTA #4
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # Pre process email headers and the body part of the message which generated by qmail, see
        # https://cr.yp.to/qmail.html
        #   e.g.) Received: (qmail 12345 invoked for bounce); 29 Apr 2009 12:34:56 -0000
        #         Subject: failure notice
        tryto  = [['(qmail ', 'invoked for bounce)'], ['(qmail ', 'invoked from ', 'network)']].freeze
        match  = 0
        match += 1 if mhead['subject'].start_with?('failure notice', 'Permanent Delivery Failure')
        mhead['received'].each do |e|
          # Received: (qmail 2222 invoked for bounce);29 Apr 2017 23:34:45 +0900
          # Received: (qmail 2202 invoked from network); 29 Apr 2018 00:00:00 +0900
          match += 1 if tryto.any? { |a| Sisimai::String.aligned(e, a) }
        end
        return nil unless match > 0

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
            readcursor |= Indicators[:deliverystatus] if StartingOf[:message].any? { |a| e.include?(a) }
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # <kijitora@example.jp>:
          # 192.0.2.153 does not like recipient.
          # Remote host said: 550 5.1.1 <kijitora@example.jp>... User Unknown
          # Giving up on 192.0.2.153.
          v = dscontents[-1]

          if e.start_with?('<') && Sisimai::String.aligned(e, ['<', '@', '>', ':'])
            # <kijitora@example.jp>:
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = Sisimai::Address.s3s4(e[e.index('<'), e.size])
            recipients += 1

          elsif dscontents.size == recipients
            # Append error message
            next if e.empty?
            v['diagnosis'] ||= ''
            v['diagnosis'] << e + ' '
            v['alterrors'] = e if e.start_with?(StartingOf[:error][0])

            next if v['rhost']
            StartingOf[:rhost].each do |r|
              # Find a remote host name
              p1 = e.index(r); next unless p1
              cm = r.size
              p2 = e.index(' ', p1 + cm + 1) || p2 = e.rindex('.') 

              v['rhost'] = e[p1 + cm, p2 - p1 - cm]
              break
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          unless e['command']
            # Get the SMTP command name for the session
            CommandSet.each_key do |r|
              # Verify each regular expression of SMTP commands
              next unless CommandSet[r].any? { |a| e['diagnosis'].include?(a) }
              e['command'] = r.upcase
              break
            end

            if e['diagnosis'].include?('Sorry, no SMTP connection got far enough; most progress was ')
              # Get the last SMTP command:from the error message
              e['command'] ||= Sisimai::SMTP::Command.find(e['diagnosis']) || '' 
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
            # Try to match with each error message in the table
            if Sisimai::String.aligned(e['diagnosis'], OnHoldPair)
              # To decide the reason require pattern match with Sisimai::Reason::* modules
              e['reason'] = 'onhold'
            else
              MessagesOf.each_key do |r|
                # Verify each regular expression of session errors
                if e['alterrors']
                  # Check the value of "alterrors"
                  next unless MessagesOf[r].any? { |a| e['alterrors'].include?(a) }
                  e['reason'] = r
                end
                break if e['reason']

                next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
                e['reason'] = r
                break
              end

              unless e['reason']
                FailOnLDAP.each_key do |r|
                  # Verify each regular expression of LDAP errors
                  next unless FailOnLDAP[r].any? { |a| e['diagnosis'].include?(a) }
                  e['reason'] = r
                  break
                end
              end

              unless e['reason']
                e['reason'] = 'expired' if e['diagnosis'].include?(HasExpired)
              end
            end
          end
          e['command'] ||= Sisimai::SMTP::Command.find(e['diagnosis'])
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Unknown MTA #4'; end
    end
  end
end

