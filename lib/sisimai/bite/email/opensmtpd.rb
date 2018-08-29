module Sisimai::Bite::Email
  # Sisimai::Bite::Email::OpenSMTPD parses a bounce email which created by
  # OpenSMTPD. Methods in the module are called from only Sisimai::Message.
  module OpenSMTPD
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/OpenSMTPD.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
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
        message: ['    This is the MAILER-DAEMON, please DO NOT REPLY to this '],
        rfc822:  ['    Below is a copy of the original message:'],
      }.freeze
      MessagesOf = {
        # smtpd/queue.c:221|  envelope_set_errormsg(&evp, "Envelope expired");
        expired: ['Envelope expired'],
        # smtpd/mta.c:976|  relay->failstr = "Invalid domain name";
        # smtpd/mta.c:980|  relay->failstr = "Domain does not exist";
        hostunknown: [
          'Invalid domain name',
          'Domain does not exist',
        ],
        # smtp/mta.c:1085|  relay->failstr = "Destination seem to reject all mails";
        notaccept: ['Destination seem to reject all mails'],
        #  smtpd/mta.c:972|  relay->failstr = "Temporary failure in MX lookup";
        networkerror: [
          'Address family mismatch on destination MXs',
          'All routes to destination blocked',
          'bad DNS lookup error code',
          'Could not retrieve source address',
          'Loop detected',
          'Network error on destination MXs',
          'No MX found for domain',
          'No MX found for destination',
          'No valid route to remote MX',
          'No valid route to destination',
          'Temporary failure in MX lookup',
        ],
        # smtpd/mta.c:1013|  relay->failstr = "Could not retrieve credentials";
        securityerror: ['Could not retrieve credentials'],
      }.freeze

      def description; return 'OpenSMTPD'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from OpenSMTPD
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
        return nil unless mhead['subject'].start_with?('Delivery status notification')
        return nil unless mhead['from'].start_with?('Mailer Daemon <')
        return nil unless mhead['received'].any? { |a| a.include?(' (OpenSMTPD) with ') }

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
            if e.start_with?(StartingOf[:rfc822][0])
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
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              v['diagnosis'] = cv[2]
              recipients += 1
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])

          MessagesOf.each_key do |r|
            # Verify each regular expression of session errors
            next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
            e['reason'] = r.to_s
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

