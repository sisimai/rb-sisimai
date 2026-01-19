module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of find() method when the value of "rhost" of the object is "mfsmax.docomo.ne.jp". This class
    # is called only Sisimai::Fact class.
    module NTTDOCOMO
      class << self
        MessagesOf = {
          'mailboxfull' => ['552 too much mail data'],
          'ratelimited' => ['552 too many recipients'],
          'syntaxerror' => ['503 bad sequence of commands', '504 command parameter not implemented'],
          'userunknown' => ['550 unknown user'],
        }.freeze

        # Detect bounce reason from NTT DOCOMO
        # @param    [Sisimai::Fact] argvs   Decoded email object
        # @return   [String]                The bounce reason for docomo.ne.jp
        def find(argvs)
          return argvs['reason'] if argvs['reason'].empty? == false
          statuscode = argvs['deliverystatus']          || ''
          thecommand = argvs['command']                 || ''
          esmtperror = argvs['diagnosticcode'].downcase || ''

          # Check the value of Status: field, an SMTP Reply Code, and the SMTP Command
          #
          #    ----- Transcript of session follows -----
          # ... while talking to mfsmax.docomo.ne.jp.:
          # >>> RCPT To:<***@docomo.ne.jp>
          # <<< 550 Unknown user ***@docomo.ne.jp
          # 550 5.1.1 <***@docomo.ne.jp>... User unknown
          # >>> DATA
          # <<< 503 Bad sequence of commands
          # ---------------------------------------------------------------------------------------
          #    ----- The following addresses had permanent fatal errors -----
          # <***@docomo.ne.jp>
          # (reason: 550 Unknown user ***@docomo.ne.jp)
          # 
          #    ----- Transcript of session follows -----
          # ... while talking to mfsmax.docomo.ne.jp.:
          # >>> DATA
          # <<< 550 Unknown user ***@docomo.ne.jp
          # 554 5.0.0 Service unavailable
          # ...
          # Final-Recipient: RFC822; ***@docomo.ne.jp
          # Action: failed
          # Status: 5.2.0
          return 'userunknown' if statuscode == '5.1.1' || statuscode == '5.9.213'
          return 'filtered'    if statuscode == '5.2.0'

          MessagesOf.each_key do |e|
            # The value of "Diagnostic-Code:" field is not empty
            # - The key name is a bounce reason name
            # - https://github.com/sisimai/go-sisimai/issues/64
            # - After March 12, 2025, if an error message contains "550 Unknown user", the
            #   bounce reason will be definitively "userunknown". This is because NTT DOCOMO
            #   no longer rejects emails via SMTP for domain-specific rejection or specified
            #   reception filters.
            return e if MessagesOf[e].any? { |a| esmtperror.include?(a) }
          end

          # A bounce reason did not decide from a status code, an error message.
          if statuscode == '5.0.0'
            # Your message to the following recipients cannot be delivered:
            #
            # <***@docomo.ne.jp>:
            # mfsmax.docomo.ne.jp [203.138.181.112]:
            # >>> RCPT TO:<***@docomo.ne.jp>
            # <<< 550 Unknown user ***@docomo.ne.jp
            # ...
            #
            # Final-Recipient: rfc822; ***@docomo.ne.jp
            # Action: failed
            # Status: 5.0.0
            # Remote-MTA: dns; mfsmax.docomo.ne.jp [203.138.181.112]
            # Diagnostic-Code: smtp; 550 Unknown user ***@docomo.ne.jp
            # -------------------------------------------------------------------------------------
            # <***@docomo.ne.jp>: host mfsmax.docomo.ne.jp[203.138.181.240] said:
            # 550 Unknown user ***@docomo.ne.jp (in reply to end of DATA
            # command)
            # ...
            # Final-Recipient: rfc822; ***@docomo.ne.jp
            # Original-Recipient: rfc822;***@docomo.ne.jp
            # Action: failed
            # Status: 5.0.0
            # Remote-MTA: dns; mfsmax.docomo.ne.jp
            # Diagnostic-Code: smtp; 550 Unknown user ***@docomo.ne.jp
            return 'userunknown' if thecommand == 'RCPT'
            return 'rejected'    if thecommand == 'DATA'
          end

          # 1. Rejected by other SMTP commands: AUTH, MAIL,
          # 2. Status: field is neither 5.0.0 nor values defined in code above
          #   もしもこのブロックを通過するNTTドコモからのエラーメッセージを見つけたら
          #   https://github.com/sisimai/rb-sisimai/issues からご連絡ねがいます。
          #
          #   If you found a error message from mfsmax.docomo.ne.jp which passes this block,
          #   please open an issue at https://github.com/sisimai/rb-sisimai/issues .
          return ""
        end

      end
    end
  end
end

