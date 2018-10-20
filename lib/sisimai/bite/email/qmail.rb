module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Qmail parses a bounce email which created by qmail.
  # Methods in the module are called from only Sisimai::Message.
  module Qmail
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/qmail.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        #  qmail-remote.c:248|    if (code >= 500) {
        #  qmail-remote.c:249|      out("h"); outhost(); out(" does not like recipient.\n");
        #  qmail-remote.c:265|  if (code >= 500) quit("D"," failed on DATA command");
        #  qmail-remote.c:271|  if (code >= 500) quit("D"," failed after I sent the message");
        #
        # Characters: K,Z,D in qmail-qmqpc.c, qmail-send.c, qmail-rspawn.c
        #  K = success, Z = temporary error, D = permanent error
        message: ['Hi. This is the qmail'],
        rfc822:  ['--- Below this line is a copy of the message.'],
        error:   ['Remote host said:'],
      }.freeze

      ReSMTP = {
        # Error text regular expressions which defined in qmail-remote.c
        # qmail-remote.c:225|  if (smtpcode() != 220) quit("ZConnected to "," but greeting failed");
        conn: %r/(?:Error:)?Connected to .+ but greeting failed[.]/,
        # qmail-remote.c:231|  if (smtpcode() != 250) quit("ZConnected to "," but my name was rejected");
        ehlo: %r/(?:Error:)?Connected to .+ but my name was rejected[.]/,
        # qmail-remote.c:238|  if (code >= 500) quit("DConnected to "," but sender was rejected");
        # reason = rejected
        mail: %r/(?:Error:)?Connected to .+ but sender was rejected[.]/,
        # qmail-remote.c:249|  out("h"); outhost(); out(" does not like recipient.\n");
        # qmail-remote.c:253|  out("s"); outhost(); out(" does not like recipient.\n");
        # reason = userunknown
        rcpt: %r/(?:Error:)?.+ does not like recipient[.]/,
        # qmail-remote.c:265|  if (code >= 500) quit("D"," failed on DATA command");
        # qmail-remote.c:266|  if (code >= 400) quit("Z"," failed on DATA command");
        # qmail-remote.c:271|  if (code >= 500) quit("D"," failed after I sent the message");
        # qmail-remote.c:272|  if (code >= 400) quit("Z"," failed after I sent the message");
        data: %r{(?:
           (?:Error:)?.+[ ]failed[ ]on[ ]DATA[ ]command[.]
          |(?:Error:)?.+[ ]failed[ ]after[ ]I[ ]sent[ ]the[ ]message[.]
          )
        }x,
      }.freeze
      # qmail-remote.c:261|  if (!flagbother) quit("DGiving up on ","");
      ReHost = %r{(?:
         Giving[ ]up[ ]on[ ](.+[0-9a-zA-Z])[.]?\z
        |Connected[ ]to[ ]([-0-9a-zA-Z.]+[0-9a-zA-Z])[ ]
        |remote[ ]host[ ]([-0-9a-zA-Z.]+[0-9a-zA-Z])[ ]said:
        )
      }x

      # qmail-send.c:922| ... (&dline[c],"I'm not going to try again; this message has been in the queue too long.\n")) nomem();
      HasExpired = 'this message has been in the queue too long.'
      ReCommands = %r/Sorry, no SMTP connection got far enough; most progress was ([A-Z]{4}) /
      ReIsOnHold = %r/\A[^ ]+ does not like recipient[.][ ]+.+this message has been in the queue too long[.]\z/
      FailOnLDAP = {
        # qmail-ldap-1.03-20040101.patch:19817 - 19866
        suspend:     ['Mailaddress is administrative?le?y disabled'],   # 5.2.1
        userunknown: ['Sorry, no mailbox here by that name'],           # 5.1.1
        exceedlimit: ['The message exeeded the maximum size the user accepts'], # 5.2.3
        systemerror: [
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
        userunknown: ['no mailbox here by that name', 'does not like recipient.'],
        # error_str.c:192|  X(EDQUOT,"disk quota exceeded")
        mailboxfull: ['disk quota exceeded'],
        # qmail-qmtpd.c:233| ... result = "Dsorry, that message size exceeds my databytes limit (#5.3.4)";
        # qmail-smtpd.c:391| ... out("552 sorry, that message size exceeds my databytes limit (#5.3.4)\r\n"); return;
        mesgtoobig:  ['Message size exceeds fixed maximum message size:'],
        # qmail-remote.c:68|  Sorry, I couldn't find any host by that name. (#4.1.2)\n"); zerodie();
        # qmail-remote.c:78|  Sorry, I couldn't find any host named ");
        hostunknown: ["Sorry, I couldn't find any host "],
        systemfull:  ['Requested action not taken: mailbox unavailable (not enough free space)'],
        systemerror: [
          'bad interpreter: No such file or directory',
          'system error',
          'Unable to',
        ],
        networkerror: [
          "Sorry, I wasn't able to establish an SMTP connection",
          "Sorry, I couldn't find a mail exchanger or IP address",
          "Sorry. Although I'm listed as a best-preference MX or A for that host",
        ],
      }.freeze

      def description; return 'qmail'; end
      def smtpagent;   return 'Email::qmail'; end
      def headerlist;  return []; end

      # Parse bounce messages from qmail
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
        # Pre process email headers and the body part of the message which generated
        # by qmail, see http://cr.yp.to/qmail.html
        #   e.g.) Received: (qmail 12345 invoked for bounce); 29 Apr 2009 12:34:56 -0000
        #         Subject: failure notice
        tryto  = /\A[(]qmail[ ]+\d+[ ]+invoked[ ]+(?:for[ ]+bounce|from[ ]+network)[)]/
        match  = 0
        match += 1 if mhead['subject'] == 'failure notice'
        match += 1 if mhead['received'].any? { |a| a =~ tryto }
        return nil unless match > 0

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
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

            # <kijitora@example.jp>:
            # 192.0.2.153 does not like recipient.
            # Remote host said: 550 5.1.1 <kijitora@example.jp>... User Unknown
            # Giving up on 192.0.2.153.
            v = dscontents[-1]

            if cv = e.match(/\A(?:To[ ]*:)?[<](.+[@].+)[>]:[ \t]*\z/)
              # <kijitora@example.jp>:
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              recipients += 1

            elsif dscontents.size == recipients
              # Append error message
              next if e.empty?
              v['diagnosis'] ||= ''
              v['diagnosis'] << e + ' '
              v['alterrors'] = e if e.start_with?(StartingOf[:error][0])

              next if v['rhost']
              next unless cv = e.match(ReHost)
              v['rhost'] = cv[1]
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis']) || ''

          unless e['command']
            # Get the SMTP command name for the session
            ReSMTP.each_key do |r|
              # Verify each regular expression of SMTP commands
              next unless e['diagnosis'] =~ ReSMTP[r]
              e['command'] = r.to_s.upcase
              break
            end

            unless e['command']
              # Verify each regular expression of patches
              if cv = e['diagnosis'].match(ReCommands) then e['command'] = cv[1].upcase end
              e['command'] ||= ''
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
            if e['diagnosis'] =~ ReIsOnHold
              # To decide the reason require pattern match with
              # Sisimai::Reason::* modules
              e['reason'] = 'onhold'
            else
              MessagesOf.each_key do |r|
                # Verify each regular expression of session errors
                if e['alterrors']
                  # Check the value of "alterrors"
                  next unless MessagesOf[r].any? { |a| e['alterrors'].include?(a) }
                  e['reason'] = r.to_s
                end
                break if e['reason']

                next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
                e['reason'] = r.to_s
                break
              end

              unless e['reason']
                FailOnLDAP.each_key do |r|
                  # Verify each regular expression of LDAP errors
                  next unless FailOnLDAP[r].any? { |a| e['diagnosis'].include?(a) }
                  e['reason'] = r.to_s
                  break
                end
              end

              unless e['reason']
                e['reason'] = 'expired' if e['diagnosis'].include?(HasExpired)
              end
            end
          end

          e['status'] = Sisimai::SMTP::Status.find(e['diagnosis'])
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

