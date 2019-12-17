module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
    # object as an argument of get() method when the value of "rhost" of the object
    # is "*.laposte.net" or "*.orange.fr".
    # This class is called only Sisimai::Data class.
    module FrancePTT
      class << self
        # Imported from p5-Sisimail/lib/Sisimai/Rhost/FrancePTT.pm
        ErrorCodes = {
          '102' => 'blocked',       # 550 mwinf5c04 ME Adresse IP source bloquee pour incident de spam. Client host blocked for spamming issues. OFR006_102 Ref
          '103' => 'blocked',       # Service refuse. Veuillez essayer plus tard.
          '104' => 'toomanyconn',   # Too many connections, slow down. LPN105_104
          '105' => nil,             # Veuillez essayer plus tard.
          '109' => nil,             # Veuillez essayer plus tard. LPN003_109
          '201' => nil,             # Veuillez essayer plus tard. OFR004_201
          '305' => 'securityerror', # 550 5.7.0 Code d'authentification invalide OFR_305
          '401' => 'blocked',       # 550 5.5.0 SPF: *** is not allowed to send mail. LPN004_401
          '402' => 'securityerror', # 550 5.5.0 Authentification requise. Authentication Required. LPN105_402
          '403' => 'rejected',      # 5.0.1 Emetteur invalide. Invalid Sender.
          '405' => 'rejected',      # 5.0.1 Emetteur invalide. Invalid Sender. LPN105_405
          '415' => 'rejected',      # Emetteur invalide. Invalid Sender. OFR_415
          '416' => 'userunknown',   # 550 5.1.1 Adresse d au moins un destinataire invalide. Invalid recipient. LPN416
          '417' => 'mailboxfull',   # 552 5.1.1 Boite du destinataire pleine. Recipient overquota.
          '418' => 'userunknown',   # Adresse d au moins un destinataire invalide
          '420' => 'suspend',       # Boite du destinataire archivee. Archived recipient.
          '421' => 'rejected',      # 5.5.3 Mail from not owned by user. LPN105_421.
          '423' => nil,             # Service refused, please try later. LPN105_423
          '424' => nil,             # Veuillez essayer plus tard. LPN105_424
          '426' => 'suspend',       # 550 5.5.0 Le compte du destinataire est bloque. The recipient account isblocked. LPN007_426
          '506' => 'spamdetected',  # Mail rejete. Mail rejected. OFR_506 [506]
          '510' => 'blocked',       # Veuillez essayer plus tard. service refused, please try later. LPN004_510
          '513' => nil,             # Mail rejete. Mail rejected. OUK_513
          '514' => 'mesgtoobig',    # Taille limite du message atteinte
        }.freeze

        # Detect bounce reason from Oranage or La Poste
        # @param    [Sisimai::Data] argvs   Parsed email object
        # @return   [String]                The bounce reason for Orange or La Poste
        def get(argvs)
          return argvs.reason unless argvs.reason.empty?

          statusmesg = argvs.diagnosticcode
          reasontext = ''

          if cv = statusmesg.match(/\b(LPN|OFR|OUK)(_[0-9]{3}|[0-9]{3}[-_][0-9]{3})\b/i)
            # OUK_513, LPN105-104, OFR102-104, ofr_506
            v = sprintf("%03d", (cv[1] + cv[2])[-3, 3])
            reasontext = ErrorCodes[v] || 'undefined'
          end
          return reasontext
        end

      end
    end
  end
end

