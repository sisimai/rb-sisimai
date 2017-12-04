module Sisimai
  module Reason
    # Sisimai::Reason::Suspend checks the bounce reason is C<suspend> or not.
    # This class is called only Sisimai::Reason class.
    #
    # This is the error that a recipient account is being suspended due to
    # unpaid or other reasons.
    module Suspend
      # Imported from p5-Sisimail/lib/Sisimai/Reason/Suspend.pm
      class << self
        def text; return 'suspend'; end
        def description
          return 'Email rejected due to a recipient account is being suspended'
        end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             Boite[ ]du[ ]destinataire[ ]archivee.+[A-Z]{3}.+420
            |email[ ]account[ ]that[ ]you[ ]tried[ ]to[ ]reach[ ]is[ ]disabled
            |invalid/inactive[ ]user
            # http://service.mail.qq.com/cgi-bin/help?subtype=1&&id=20022&&no=1000742
            |is[ ]a[ ]deactivated[ ]mailbox
            |mailbox[ ](?:
               currently[ ]suspended
              |unavailable[ ]or[ ]access[ ]denied
              )
            |recipient[ ](?:
               rejected:[ ]Temporarily[ ]inactive
              |suspend[ ]the[ ]service
              )
            |sorry[ ]your[ ]message[ ]to[ ].+[ ]cannot[ ]be[ ]delivered[.][ ]this[ ]
              account[ ]has[ ]been[ ]disabled[ ]or[ ]discontinued
            |The[ ]domain[ ].+[ ]is[ ]currently[ ]suspended
            |User[ ].+[ ]temporary[ ]locked
            |user[ ]suspended   # http://mail.163.com/help/help_spam_16.htm
            |vdelivermail:[ ]account[ ]is[ ]locked[ ]email[ ]bounced
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        # The envelope recipient's mailbox is suspended or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is mailbox suspended
        #                                   false: is not suspended
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return nil unless argvs.deliverystatus.size > 0
          return true if argvs.reason == Sisimai::Reason::Suspend.text
          return true if Sisimai::Reason::Suspend.match(argvs.diagnosticcode)
          return false
        end

      end
    end
  end
end

