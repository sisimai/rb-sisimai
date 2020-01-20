module Sisimai::Lhost
  # Sisimai::Lhost::SurfControl parses a bounce email which created by
  # WebSense SurfControl.
  # Methods in the module are called from only Sisimai::Message.
  module SurfControl
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Lhost/SurfControl.pm
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r|^Content-Type:[ ]message/rfc822|.freeze
      StartingOf = { message: ['Your message could not be sent.'] }.freeze

      def description; return 'WebSense SurfControl'; end
      def smtpagent;   return Sisimai::Lhost.smtpagent(self); end
      # X-SEF-ZeroHour-RefID: fgs=000000000
      # X-SEF-Processed: 0_0_0_000__2010_04_29_23_34_45
      # X-Mailer: SurfControl E-mail Filter
      def headerlist;  return %w[x-sef-processed x-mailer]; end

      # Parse bounce messages from SurfControl
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
      def make(mhead, mbody)
        # :'from' => %r/ [(]Mail Delivery System[)]\z/,
        return nil unless mhead['x-sef-processed']
        return nil unless mhead['x-mailer']
        return nil unless mhead['x-mailer'] == 'SurfControl E-mail Filter'

        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readslices = ['']
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email
          # to the previous line of the beginning of the original message.
          readslices << e # Save the current line for the next loop

          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e == StartingOf[:message][0]
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # Your message could not be sent.
          # A transcript of the attempts to send the message follows.
          # The number of attempts made: 1
          # Addressed To: kijitora@example.com
          #
          # Thu 29 Apr 2010 23:34:45 +0900
          # Failed to send to identified host,
          # kijitora@example.com: [192.0.2.5], 550 kijitora@example.com... No such user
          # --- Message non-deliverable.
          v = dscontents[-1]

          if cv = e.match(/\AAddressed To:[ ]*([^ ]+?[@][^ ]+?)\z/)
            # Addressed To: kijitora@example.com
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = cv[1]
            recipients += 1

          elsif e =~ /\A(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)[ ,]/
            # Thu 29 Apr 2010 23:34:45 +0900
            v['date'] = e

          elsif cv = e.match(/\A[^ ]+[@][^ ]+:[ ]*\[(\d+[.]\d+[.]\d+[.]\d)\],[ ]*(.+)\z/)
            # kijitora@example.com: [192.0.2.5], 550 kijitora@example.com... No such user
            v['rhost'] = cv[1]
            v['diagnosis'] = cv[2]
          else
            # Fallback, parse RFC3464 headers.
            if f = Sisimai::RFC1894.match(e)
              # "e" matched with any field defined in RFC3464
              next unless o = Sisimai::RFC1894.field(e)
              next if o[1] == 'final-recipient'
              next unless fieldtable[o[0]]
              v[fieldtable[o[0]]] = o[2]
            else
              # Continued line of the value of Diagnostic-Code field
              next unless readslices[-2].start_with?('Diagnostic-Code:')
              next unless cv = e.match(/\A[ \t]+(.+)\z/)
              v['diagnosis'] << ' ' << cv[1]
              readslices[-1] = 'Diagnostic-Code: ' << e
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent']     = self.smtpagent
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e.each_key { |a| e[a] ||= '' }
        end

        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end

    end
  end
end

