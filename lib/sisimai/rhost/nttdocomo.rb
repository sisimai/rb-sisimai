module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of get() method when the value of "rhost" of the object is "mfsmax.docomo.ne.jp". This class
    # is called only Sisimai::Fact class.
    module NTTDOCOMO
      class << self
        MessagesOf = {
          'mailboxfull' => %r/552 too much mail data/,
          'toomanyconn' => %r/552 too many recipients/,
          'syntaxerror' => %r/(?:503 bad sequence of commands|504 command parameter not implemented)/,
        }.freeze

        # Detect bounce reason from NTT DOCOMO
        # @param    [Sisimai::Fact] argvs   Parsed email object
        # @return   [String]                The bounce reason for docomo.ne.jp
        def get(argvs)
          statuscode = argvs['deliverystatus']          || ''
          commandtxt = argvs['smtpcommand']             || ''
          esmtperror = argvs['diagnosticcode'].downcase || ''
          reasontext = ''

          # Check the value of Status: field, an SMTP Reply Code, and the SMTP Command
          if statuscode == '5.1.1' || statuscode == '5.0.911'
            #    ----- Transcript of session follows -----
            # ... while talking to mfsmax.docomo.ne.jp.:
            # >>> RCPT To:<***@docomo.ne.jp>
            # <<< 550 Unknown user ***@docomo.ne.jp
            # 550 5.1.1 <***@docomo.ne.jp>... User unknown
            # >>> DATA
            # <<< 503 Bad sequence of commands
            reasontext = 'userunknown'

          elsif statuscode == '5.2.0'
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
            reasontext = 'filtered'

          else
            # The value of "Diagnostic-Code:" field is not empty
            MessagesOf.each_key do |e|
              # Try to match the error message with message patterns defined in "MessagesOf"
              next unless esmtperror =~ MessagesOf[e]
              reasontext = e
              break
            end
          end

          if reasontext.empty?
            # A bounce reason did not decide from a status code, an error message.
            if statuscode == '5.0.0'
              # Status: 5.0.0
              if commandtxt == 'RCPT'
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
                reasontext = 'userunknown'

              elsif commandtxt == 'DATA'
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
                reasontext = 'rejected'

              else
                # Rejected by other SMTP commands: AUTH, MAIL,
                #   もしもこのブロックを通過するNTTドコモからのエラーメッセージを見つけたら
                #   https://github.com/sisimai/p5-sisimai/issues からご連絡ねがいます。
                #
                #   If you found a error message from mfsmax.docomo.ne.jp which passes this block,
                #   please open an issue at https://github.com/sisimai/p5-sisimai/issues .
              end
            else
              # Status: field is neither 5.0.0 nor values defined in code above
              #   もしもこのブロックを通過するNTTドコモからのエラーメッセージを見つけたら
              #   https://github.com/sisimai/p5-sisimai/issues からご連絡ねがいます。
              #
              #   If you found a error message from mfsmax.docomo.ne.jp which passes this block,
              #
            end
          end

          return reasontext
        end

      end
    end
  end
end

