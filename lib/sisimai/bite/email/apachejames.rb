module Sisimai::Bite::Email
  # Sisimai::Bite::::Email::ApacheJames parses a bounce email which created by
  # ApacheJames. Methods in the module are called from only Sisimai::Message.
  module ApacheJames
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/ApacheJames.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = {
        # apache-james-2.3.2/src/java/org/apache/james/transport/mailets/
        #   AbstractNotify.java|124:  out.println("Error message below:");
        #   AbstractNotify.java|128:  out.println("Message details:");
        message: [''],
        rfc822:  ['Content-Type: message/rfc822'],
        error:   ['Error message below:'],
      }.freeze

      def description; return 'Java Apache Mail Enterprise Server'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return []; end

      # Parse bounce messages from Apache James
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
        match += 1 if mhead['subject'] == '[BOUNCE]'
        match += 1 if mhead['message-id'].to_s.include?('.JavaMail.')
        match += 1 if mhead['received'].any? { |a| a.include?('JAMES SMTP Server') }
        return nil unless match > 0

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        diagnostic = ''     # (String) Alternative diagnostic message
        subjecttxt = nil    # (String) Alternative Subject text
        gotmessage = nil    # (Boolean) Flag for error message
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

            # Message details:
            #   Subject: Nyaaan
            #   Sent date: Thu Apr 29 01:20:50 JST 2015
            #   MAIL FROM: shironeko@example.jp
            #   RCPT TO: kijitora@example.org
            #   From: Neko <shironeko@example.jp>
            #   To: kijitora@example.org
            #   Size (in bytes): 1024
            #   Number of lines: 64
            v = dscontents[-1]

            if cv = e.match(/\A[ ][ ]RCPT[ ]TO:[ ]([^ ]+[@][^ ]+)\z/)
              #   RCPT TO: kijitora@example.org
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              recipients += 1

            elsif cv = e.match(/\A[ ][ ]Sent[ ]date:[ ](.+)\z/)
              #   Sent date: Thu Apr 29 01:20:50 JST 2015
              v['date'] = cv[1]

            elsif cv = e.match(/\A[ ][ ]Subject:[ ](.+)\z/)
              #   Subject: Nyaaan
              subjecttxt = cv[1]
            else
              next if gotmessage
              if v['diagnosis']
                # Get an error message text
                if e.start_with?('Message details:')
                  # Message details:
                  #   Subject: nyaan
                  #   ...
                  gotmessage = true
                else
                  # Append error message text like the followng:
                  #   Error message below:
                  #   550 - Requested action not taken: no such user here
                  v['diagnosis'] << ' ' << e
                end
              else
                # Error message below:
                # 550 - Requested action not taken: no such user here
                v['diagnosis'] = e if e == StartingOf[:error][0]
                unless gotmessage
                  v['diagnosis'] ||= ''
                  v['diagnosis'] << ' ' + e
                end
              end
            end
          end
        end
        return nil unless recipients > 0

        unless rfc822list.any? { |a| a.start_with?('Subject:') }
          # Set the value of subjecttxt as a Subject if there is no original
          # message in the bounce mail.
          rfc822list << ('Subject: ' << subjecttxt)
        end

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'] || diagnostic)
          e.each_key { |a| e[a] ||= '' }
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

