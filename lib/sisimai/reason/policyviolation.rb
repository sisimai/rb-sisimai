module Sisimai
  module Reason
    # Sisimai::Reason::PolicyViolation checks the bounce reason is "policyviolation"
    # or not. This class is called only Sisimai::Reason class.
    #
    # This is the error that a policy violation was detected on a destination mail
    # host. When a header content or a format of the original message violates
    # security policies, or multiple addresses exist in the From: header, Sisimai
    # will set "policyviolation".
    #
    #   Action: failed
    #   Status: 5.7.9
    #   Remote-MTA: DNS; mx.example.co.jp
    #   Diagnostic-Code: SMTP; 554 5.7.9 Header error
    #
    module PolicyViolation
      # Imported from p5-Sisimail/lib/Sisimai/Reason/PolicyViolation.pm
      class << self
        def text; return 'policyviolation'; end
        def description
          return 'Email rejected due to policy violation on a destination host'
        end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        # @since 4.22.0
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             because[ ]the[ ]recipient[ ]is[ ]not[ ]accepting[ ]mail[ ]with[ ](?:attachments|embedded[ ]images) # AOL Phoenix
            |closed[ ]mailing[ ]list
            |email[ ](?:
               not[ ]accepted[ ]for[ ]policy[ ]reasons
              # http://kb.mimecast.com/Mimecast_Knowledge_Base/Administration_Console/Monitoring/Mimecast_SMTP_Error_Codes#554
              |rejected[ ]due[ ]to[ ]security[ ]policies
              )
            |header[ ]are[ ]not[ ]accepted
            |Header[ ]error
            |Messages[ ]with[ ]multiple[ ]addresses
            |You[ ]have[ ]exceeded[ ]the[ ]the[ ]allowable[ ]number[ ]of[ ]posts[ ]without[ ]solving[ ]a[ ]captcha
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        # The bounce reason is security error or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is policy violation
        #                                   false: is not policy violation
        # @since 4.22.0
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs)
          return nil
        end

      end
    end
  end
end

