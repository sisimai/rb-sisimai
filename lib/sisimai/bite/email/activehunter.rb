module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Activehunter parses a bounce email which created
  # by TransWARE Active!hunter.
  # Methods in the module are called from only Sisimai::Message.
  module Activehunter
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Activehunter.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        message: ['  ----- The following addresses had permanent fatal errors -----'],
        rfc822:  ['Content-type: message/rfc822'],
      }.freeze

      def description; return 'TransWARE Active!hunter'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return ['X-AHMAILID']; end

      # Parse bounce messages from TransWARE Active!hunter
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
        # :from    => %r/\A"MAILER-DAEMON"/,
        # :subject => %r/FAILURE NOTICE :/,
        return nil unless mhead['x-ahmailid']

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

            #  ----- The following addresses had permanent fatal errors -----
            #
            # >>> kijitora@example.org <kijitora@example.org>
            #
            #  ----- Transcript of session follows -----
            # 550 sorry, no mailbox here by that name (#5.1.1 - chkusr)
            v = dscontents[-1]

            if cv = e.match(/\A[>]{3}[ \t]+.+[<]([^ ]+?[@][^ ]+?)[>]\z/)
              # >>> kijitora@example.org <kijitora@example.org>
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              v['diagnosis'] = ''
              recipients += 1
            else
              #  ----- Transcript of session follows -----
              # 550 sorry, no mailbox here by that name (#5.1.1 - chkusr)
              next unless e =~ /\A[0-9A-Za-z]+/
              next unless v['diagnosis'].empty?
              v['diagnosis'] = e
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['agent']     = self.smtpagent
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

