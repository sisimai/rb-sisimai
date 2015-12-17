module Sisimai
  module MTA
    # Sisimai::MTA::OpenSMTPD parses a bounce email which created by OpenSMTPD.
    # Methods in the module are called from only Sisimai::Message.
    module OpenSMTPD
      # Imported from p5-Sisimail/lib/Sisimai/MTA/OpenSMTPD.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :from     => %r/\AMailer Daemon [<][^ ]+[@]/,
          :subject  => %r/\ADelivery status notification/,
          :received => %r/[ ][(]OpenSMTPD[)][ ]with[ ]/,
        }
        # http://www.openbsd.org/cgi-bin/man.cgi?query=smtpd&sektion=8
        # opensmtpd-5.4.2p1/smtpd/
        #   bounce.c/317:#define NOTICE_INTRO \
        #   bounce.c/318:    "    Hi!\n\n"    \
        #   bounce.c/319:    "    This is the MAILER-DAEMON, please DO NOT REPLY to this e-mail.\n"
        #   bounce.c/320:
        #   bounce.c/321:const char *notice_error =
        #   bounce.c/322:    "    An error has occurred while attempting to deliver a message for\n"
        #   bounce.c/323:    "    the following list of recipients:\n\n";
        #   bounce.c/324:
        #   bounce.c/325:const char *notice_warning =
        #   bounce.c/326:    "    A message is delayed for more than %s for the following\n"
        #   bounce.c/327:    "    list of recipients:\n\n";
        #   bounce.c/328:
        #   bounce.c/329:const char *notice_warning2 =
        #   bounce.c/330:    "    Please note that this is only a temporary failure report.\n"
        #   bounce.c/331:    "    The message is kept in the queue for up to %s.\n"
        #   bounce.c/332:    "    You DO NOT NEED to re-send the message to these recipients.\n\n";
        #   bounce.c/333:
        #   bounce.c/334:const char *notice_success =
        #   bounce.c/335:    "    Your message was successfully delivered to these recipients.\n\n";
        #   bounce.c/336:
        #   bounce.c/337:const char *notice_relay =
        #   bounce.c/338:    "    Your message was relayed to these recipients.\n\n";
        #   bounce.c/339:
        Re1 = {
          :begin  => %r/\A\s*This is the MAILER-DAEMON, please DO NOT REPLY to this e-mail[.]\z/,
          :rfc822 => %r/\A\s*Below is a copy of the original message:\z/,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        ReFailure = {
          'expired' => %r{
            # smtpd/queue.c:221|  envelope_set_errormsg(&evp, "Envelope expired");
            Envelope[ ]expired
          }x,
          'hostunknown' => %r{(?:
            # smtpd/mta.c:976|  relay->failstr = "Invalid domain name";
             Invalid[ ]domain[ ]name
            # smtpd/mta.c:980|  relay->failstr = "Domain does not exist";
            |Domain[ ]does[ ]not[ ]exist
            )
          }x,
          'notaccept' => %r{
            # smtp/mta.c:1085|  relay->failstr = "Destination seem to reject all mails";
            Destination[ ]seem[ ]to[ ]reject[ ]all[ ]mails
          }x,
          'networkerror' => %r{(?>
            #  smtpd/mta.c:972|  relay->failstr = "Temporary failure in MX lookup";
             Address[ ]family[ ]mismatch[ ]on[ ]destination[ ]MXs
            |All[ ]routes[ ]to[ ]destination[ ]blocked
            |bad[ ]DNS[ ]lookup[ ]error[ ]code
            |Could[ ]not[ ]retrieve[ ]source[ ]address
            |Loop[ ]detected
            |Network[ ]error[ ]on[ ]destination[ ]MXs
            |No[ ](?>
               MX[ ]found[ ]for[ ](?:domain|destination)
              |valid[ ]route[ ]to[ ](?:remote[ ]MX|destination)
              )
            |Temporary[ ]failure[ ]in[ ]MX[ ]lookup
            )
          }x,
          'securityerror' => %r{
            # smtpd/mta.c:1013|  relay->failstr = "Could not retrieve credentials";
            Could[ ]not[ ]retrieve[ ]credentials
          }x,
        }
        Indicators = Sisimai::MTA.INDICATORS
        LongFields = Sisimai::RFC5322.LONGFIELDS
        RFC822Head = Sisimai::RFC5322.HEADERFIELDS

        def description; return 'OpenSMTPD'; end
        def smtpagent;   return 'OpenSMTPD'; end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from Sendmail
        # @param         [Hash] mhead       Message header of a bounce email
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
          return nil unless mhead['subject'] =~ Re0[:subject]
          return nil unless mhead['from']    =~ Re0[:from]
          return nil unless mhead['received'].find { |a| a =~ Re0[:received] }

          dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
          hasdivided = mbody.split("\n")
          havepassed = [''];
          rfc822next = { 'from' => false, 'to' => false, 'subject' => false }
          rfc822part = ''     # (String) message/rfc822-headers part
          previousfn = ''     # (String) Previous field name
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header

          hasdivided.each do |e|
            # Save the current line for the next loop
            havepassed << e; p = havepassed[-2]

            if readcursor == 0
              # Beginning of the bounce message or delivery status part
              if e =~ Re1[:begin]
                readcursor |= Indicators[:'deliverystatus']
                next
              end
            end

            if readcursor & Indicators[:'message-rfc822'] == 0
              # Beginning of the original message part
              if e =~ Re1[:rfc822]
                readcursor |= Indicators[:'message-rfc822']
                next
              end
            end

            if readcursor & Indicators[:'message-rfc822'] > 0
              # After "message/rfc822"
              if cv = e.match(/\A([-0-9A-Za-z]+?)[:][ ]*.+\z/)
                # Get required headers only
                lhs = cv[1].downcase
                previousfn = '';
                next unless RFC822Head.key?(lhs)

                previousfn  = lhs
                rfc822part += e + "\n"

              elsif e =~ /\A\s+/
                # Continued line from the previous line
                next if rfc822next[previousfn]
                rfc822part += e + "\n" if LongFields.key?(previousfn)

              else
                # Check the end of headers in rfc822 part
                next unless LongFields.key?(previousfn)
                next unless e.empty?
                rfc822next[previousfn] = true
              end

            else
              # Before "message/rfc822"
              next if readcursor & Indicators[:'deliverystatus'] == 0
              next if e.empty?

              #    Hi!
              #
              #    This is the MAILER-DAEMON, please DO NOT REPLY to this e-mail.
              #
              #    An error has occurred while attempting to deliver a message for
              #    the following list of recipients:
              #
              # kijitora@example.jp: 550 5.2.2 <kijitora@example>... Mailbox Full
              #
              #    Below is a copy of the original message:
              v = dscontents[-1]

              if cv = e.match(/\A([^ ]+?[@][^ ]+?):?[ ](.+)\z/)
                # kijitora@example.jp: 550 5.2.2 <kijitora@example>... Mailbox Full
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                v['diagnosis'] = cv[2]
                recipients += 1
              end
            end
          end

          return nil unless recipients > 0
          require 'sisimai/string'
          require 'sisimai/smtp/status'

          dscontents.map do |e|
            # Set default values if each value is empty.
            e['agent'] = Sisimai::MTA::OpenSMTPD.smtpagent

            if mhead['received'].size > 0
              # Get localhost and remote host name from Received header.
              r = mhead['received']
              ['lhost', 'rhost'].each { |a| e[a] ||= '' }
              e['lhost'] = Sisimai::RFC5322.received(r[0]).shift if e['lhost'].empty?
              e['rhost'] = Sisimai::RFC5322.received(r[-1]).pop  if e['rhost'].empty?
            end
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

            ReFailure.each_key do |r|
              # Verify each regular expression of session errors
              next unless e['diagnosis'] =~ ReFailure[r]
              e['reason'] = r
              break
            end

            e['status'] = Sisimai::SMTP::Status.find(e['diagnosis'])
            e['spec']   = e['reason'] == 'mailererror' ? 'X-UNIX' : 'SMTP'
            e['action'] = 'failed' if e['status'] =~ /\A[45]/
            e.each_key { |a| e[a] ||= '' }
          end
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

