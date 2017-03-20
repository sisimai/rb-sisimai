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
        def description
          return 'Email rejected due to an email size is too big for a destination mail server'
        end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             exceeded[ ]maximum[ ]inbound[ ]message[ ]size
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
          return true if argvs.reason == Sisimai::Reason::MesgTooBig.text

          require 'sisimai/smtp/status'
          statuscode = argvs.deliverystatus || ''
          diagnostic = argvs.diagnosticcode || ''
          reasontext = Sisimai::Reason::MesgTooBig.text
          tempreason = Sisimai::SMTP::Status.name(statuscode)
          v = false

          if tempreason == reasontext
            # Delivery status code points "mesgtoobig".
            # Status: 5.3.4
            # Diagnostic-Code: SMTP; 552 5.3.4 Error: message file too big
            v = true
          else
            if tempreason == 'exceedlimit' || statuscode == '5.2.3'
              #  5.2.3   Message length exceeds administrative limit
              v = false
            else
              # Check the value of Diagnosic-Code: header with patterns
              v = true if Sisimai::Reason::MesgTooBig.match(diagnostic)
            end
          end

          return v
        end

      end
    end
  end
end



