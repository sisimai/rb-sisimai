module Sisimai::Bite::Email
  # Sisimai::Bite::Email::Exchange2007 parses a bounce email which created by
  # Microsoft Exchange Server 2007.
  # Methods in the module are called from only Sisimai::Message.
  module Exchange2007
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/Exchange2007.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = { rfc822: ['Original message headers:'] }.freeze
      MarkingsOf = {
        message: %r/ Microsoft Exchange Server 20\d{2}/,
        error:   %r/ ((?:RESOLVER|QUEUE)[.][A-Za-z]+(?:[.]\w+)?);/,
        rhost:   %r/\AGenerating server:[ ]?(.*)/,
      }.freeze
      NDRSubject = {
        :'SMTPSEND.DNS.NonExistentDomain'=> 'hostunknown',   # 554 5.4.4 SMTPSEND.DNS.NonExistentDomain
        :'SMTPSEND.DNS.MxLoopback'       => 'networkerror',  # 554 5.4.4 SMTPSEND.DNS.MxLoopback
        :'RESOLVER.ADR.BadPrimary'       => 'systemerror',   # 550 5.2.0 RESOLVER.ADR.BadPrimary
        :'RESOLVER.ADR.RecipNotFound'    => 'userunknown',   # 550 5.1.1 RESOLVER.ADR.RecipNotFound
        :'RESOLVER.ADR.ExRecipNotFound'  => 'userunknown',   # 550 5.1.1 RESOLVER.ADR.ExRecipNotFound
        :'RESOLVER.ADR.RecipLimit'       => 'toomanyconn',   # 550 5.5.3 RESOLVER.ADR.RecipLimit
        :'RESOLVER.ADR.InvalidInSmtp'    => 'systemerror',   # 550 5.1.0 RESOLVER.ADR.InvalidInSmtp
        :'RESOLVER.ADR.Ambiguous'        => 'systemerror',   # 550 5.1.4 RESOLVER.ADR.Ambiguous, 420 4.2.0 RESOLVER.ADR.Ambiguous
        :'RESOLVER.RST.AuthRequired'     => 'filtered',      # 550 5.7.1 RESOLVER.RST.AuthRequired
        :'RESOLVER.RST.NotAuthorized'    => 'rejected',      # 550 5.7.1 RESOLVER.RST.NotAuthorized
        :'RESOLVER.RST.RecipSizeLimit'   => 'mesgtoobig',    # 550 5.2.3 RESOLVER.RST.RecipSizeLimit
        :'QUEUE.Expired'                 => 'expired',       # 550 4.4.7 QUEUE.Expired
      }.freeze

      def description; return 'Microsoft Exchange Server 2007'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return ['Content-Language']; end

      # Parse bounce messages from Microsoft Exchange Server 2007
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
        return nil unless mhead['subject'].start_with?('Undeliverable:')
        return nil unless mhead['content-language']
        return nil unless mhead['content-language'] =~ /\A[a-z]{2}(?:[-][A-Z]{2})?\z/

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        connvalues = 0      # (Integer) Flag, 1 if all the value of connheader have been set
        connheader = {
          'rhost' => '',    # The value of Reporting-MTA header or "Generating Server:"
        }
        v = nil

        while e = hasdivided.shift do
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e =~ MarkingsOf[:message]
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

            if connvalues == connheader.keys.size
              # Diagnostic information for administrators:
              #
              # Generating server: mta2.neko.example.jp
              #
              # kijitora@example.jp
              # #550 5.1.1 RESOLVER.ADR.RecipNotFound; not found ##
              #
              # Original message headers:
              v = dscontents[-1]

              if cv = e.match(/\A([^ @]+[@][^ @]+)\z/)
                # kijitora@example.jp
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::Bite.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                v['diagnosis'] = ''
                recipients += 1

              elsif cv = e.match(/\A[#]([45]\d{2})[ ]([45][.]\d[.]\d+)[ ].+\z/)
                # #550 5.1.1 RESOLVER.ADR.RecipNotFound; not found ##
                # #550 5.2.3 RESOLVER.RST.RecipSizeLimit; message too large for this recipien=
                # t ##
                v['replycode'] = cv[1]
                v['status']    = cv[2]
                v['diagnosis'] = e
              else
                if !v['diagnosis'].to_s.empty? && v['diagnosis'].end_with?('=')
                  # Continued line of error messages
                  v['diagnosis']  = v['diagnosis'].chomp('=')
                  v['diagnosis'] << e
                end
              end
            else
              # Diagnostic information for administrators:
              #
              # Generating server: mta22.neko.example.org
              if cv = e.match(MarkingsOf[:rhost])
                # Generating server: mta22.neko.example.org
                next unless connheader['rhost'].empty?
                connheader['rhost'] = cv[1]
                connvalues += 1
              end
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          if cv = e['diagnosis'].match(MarkingsOf[:error])
            # #550 5.1.1 RESOLVER.ADR.RecipNotFound; not found ##
            f = cv[1]
            NDRSubject.each_key do |r|
              # Try to match with error subject strings
              next unless f == r.to_s
              e['reason'] = NDRSubject[r]
              break
            end
          end
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['agent']     = self.smtpagent
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

