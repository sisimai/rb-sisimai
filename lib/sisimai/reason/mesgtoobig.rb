module Sisimai
  module Reason
    # This is the error that a sent email size is too big for a destination mail
    # server. In many case, There are many attachment files with email, or the
    # file size is too large.
    # Sisimai will set "mesgtoobig" to the reason of email bounce if the value
    # of Status: field in a bounce email is "5.3.4".
    module MesgTooBig
      # Imported from p5-Sisimail/lib/Sisimai/Reason/MesgTooBig.pm
      class << self
        def text; return 'mesgtoobig'; end
        def description; return 'Email rejected due to an email size is too big for a destination mail server'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             exceeded[ ]maximum[ ]inbound[ ]message[ ]size
            |Line[ ]limit[ ]exceeded
            |max[ ]message[ ]size[ ]exceeded
            |message[ ](?:
               file[ ]too[ ]big
              |length[ ]exceeds[ ]administrative[ ]limit
              |size[ ]exceeds[ ](?:
                 fixed[ ]limit
                |fixed[ ]maximum[ ]message[ ]size
                |maximum[ ]value
                )
              |too[ ]big
              |too[ ]large[ ]for[ ]this[ ].+
              )
            |size[ ]limit
            |Taille[ ]limite[ ]du[ ]message[ ]atteinte.+[A-Z]{3}.+514
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        # The message size is too big for the remote host
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is too big message size
        #                                   false: is not big
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return true if argvs.reason == 'mesgtoobig'

          require 'sisimai/smtp/status'
          statuscode = argvs.deliverystatus || ''
          tempreason = Sisimai::SMTP::Status.name(statuscode)

          # Delivery status code points "mesgtoobig".
          # Status: 5.3.4
          # Diagnostic-Code: SMTP; 552 5.3.4 Error: message file too big
          return true if tempreason == 'mesgtoobig'

          #  5.2.3   Message length exceeds administrative limit
          return false if( tempreason == 'exceedlimit' || statuscode == '5.2.3' )

          # Check the value of Diagnosic-Code: header with patterns
          return true if match(argvs.diagnosticcode)
          return false
        end

      end
    end
  end
end



