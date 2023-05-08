module Sisimai::Lhost
  # Sisimai::Lhost::Exchange2007 parses a bounce email which created by Microsoft Exchange Server 2007.
  # Methods in the module are called from only Sisimai::Message.
  module Exchange2007
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = [
        'Original message headers:',                # en-US
        "tes de message d'origine :",               # fr-FR/En-tÃªtes de message d'origine
        'Intestazioni originali del messaggio:',    # it-CH
      ].freeze
      MarkingsOf = {
        message: [
          'Diagnostic information for administrators:',           # en-US
          'Informations de diagnostic pour les administrateurs',  # fr-FR
          'Informazioni di diagnostica per gli amministratori',   # it-CH
        ],
        error:   [' RESOLVER.', ' QUEUE.'],
        rhost:   [
          'Generating server',        # en-US
          'Serveur de g',             # fr-FR/Serveur de g’Hn’Hration
          'Server di generazione',    # it-CH
        ]
      }.freeze
      NDRSubject = {
        'SMTPSEND.DNS.NonExistentDomain' => 'hostunknown',   # 554 5.4.4 SMTPSEND.DNS.NonExistentDomain
        'SMTPSEND.DNS.MxLoopback'        => 'networkerror',  # 554 5.4.4 SMTPSEND.DNS.MxLoopback
        'RESOLVER.ADR.BadPrimary'        => 'systemerror',   # 550 5.2.0 RESOLVER.ADR.BadPrimary
        'RESOLVER.ADR.RecipNotFound'     => 'userunknown',   # 550 5.1.1 RESOLVER.ADR.RecipNotFound
        'RESOLVER.ADR.ExRecipNotFound'   => 'userunknown',   # 550 5.1.1 RESOLVER.ADR.ExRecipNotFound
        'RESOLVER.ADR.RecipLimit'        => 'toomanyconn',   # 550 5.5.3 RESOLVER.ADR.RecipLimit
        'RESOLVER.ADR.InvalidInSmtp'     => 'systemerror',   # 550 5.1.0 RESOLVER.ADR.InvalidInSmtp
        'RESOLVER.ADR.Ambiguous'         => 'systemerror',   # 550 5.1.4 RESOLVER.ADR.Ambiguous, 420 4.2.0 RESOLVER.ADR.Ambiguous
        'RESOLVER.RST.AuthRequired'      => 'securityerror', # 550 5.7.1 RESOLVER.RST.AuthRequired
        'RESOLVER.RST.NotAuthorized'     => 'rejected',      # 550 5.7.1 RESOLVER.RST.NotAuthorized
        'RESOLVER.RST.RecipSizeLimit'    => 'mesgtoobig',    # 550 5.2.3 RESOLVER.RST.RecipSizeLimit
        'QUEUE.Expired'                  => 'expired',       # 550 4.4.7 QUEUE.Expired
      }.freeze

      # Parse bounce messages from Microsoft Exchange Server 2007
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        # Content-Language: en-US, fr-FR
        match   = nil
        match ||= 1 if mhead['subject'].start_with?('Undeliverable')
        match ||= 1 if mhead['subject'].start_with?('Non_remis_')
        match ||= 1 if mhead['subject'].start_with?('Non recapitabile')
        return nil unless match
        return nil unless mhead['content-language']

        match += 1 if mhead['content-language'].size == 2 # JP
        match += 1 if mhead['content-language'].size == 5 # ja-JP
        return nil unless match > 1

        # These headers exist only a bounce mail from Office365
        return nil if mhead['x-ms-exchange-crosstenant-originalarrivaltime']
        return nil if mhead['x-ms-exchange-crosstenant-fromentityheader']

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        connvalues = 0      # (Integer) Flag, 1 if all the value of connheader have been set
        connheader = {
          'rhost' => '',    # The value of Reporting-MTA header or "Generating Server:"
        }
        v = nil

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if MarkingsOf[:message].any? { |a| e.start_with?(a) }
            next
          end
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

            if e.include?('@') && e.include?(' ') == false
              # kijitora@example.jp
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = Sisimai::Address.s3s4(e)
              v['diagnosis'] = ''
              recipients += 1

            elsif cv = e.match(/([45]\d{2})[ ]([45][.]\d[.]\d+)?[ ]?.+\z/)
              # #550 5.1.1 RESOLVER.ADR.RecipNotFound; not found ##
              # #550 5.2.3 RESOLVER.RST.RecipSizeLimit; message too large for this recipient ##
              # Remote Server returned '550 5.1.1 RESOLVER.ADR.RecipNotFound; not found'
              # 3/09/2016 8:05:56 PM - Remote Server at mydomain.com (10.1.1.3) returned '550 4.4.7 QUEUE.Expired; message expired'
              v['replycode'] = cv[1]
              v['status']    = cv[2]
              v['diagnosis'] = e
            else
              # Continued line of error messages
              next if v['diagnosis'].to_s.empty?
              next unless v['diagnosis'].end_with?('=')
              v['diagnosis']  = v['diagnosis'].chomp('=')
              v['diagnosis'] << e
            end
          else
            # Diagnostic information for administrators:
            #
            # Generating server: mta22.neko.example.org
            next unless MarkingsOf[:rhost].any? { |a| e.start_with?(a) }
            next unless connheader['rhost'].empty?
            connheader['rhost'] = e[e.index(':') + 1, e.size]
            connvalues += 1
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          p = -1
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          MarkingsOf[:error].each do |q|
            # Find an error message, get an error code.
            p = e['diagnosis'].index(q) || -1
            break if p > -1
          end
          next unless p > 0

          # #550 5.1.1 RESOLVER.ADR.RecipNotFound; not found ##
          f = e['diagnosis'][p + 1, e['diagnosis'].index(';') - p -1]
          NDRSubject.each_key do |r|
            # Try to match with error subject strings
            next unless f == r
            e['reason'] = NDRSubject[r]
            break
          end
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Microsoft Exchange Server 2007'; end
    end
  end
end

