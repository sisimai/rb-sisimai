module Sisimai
  module Reason
    module NoRelaying
      # Imported from p5-Sisimail/lib/Sisimai/Reason/NoRelaying.pm
      class << self
        def text; return 'norelaying'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             Insecure[ ]Mail[ ]Relay
            |mail[ ]server[ ]requires[ ]authentication[ ]when[ ]attempting[ ]to[ ]
              send[ ]to[ ]a[ ]non-local[ ]e-mail[ ]address    # MailEnable 
            |not[ ]allowed[ ]to[ ]relay[ ]through[ ]this[ ]machine
            |relay[ ](?:
               access[ ]denied
              |denied
              |not[ ]permitted
              )
            |relaying[ ]denied  # Sendmail
            |that[ ]domain[ ]isn[']t[ ]in[ ]my[ ]list[ ]of[ ]allowed[ ]rcpthost
            |Unable[ ]to[ ]relay[ ]for
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        # Whether the message is rejected by 'Relaying denied'
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: Rejected for "relaying denied"
        #                                   false: is not
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          currreason = argvs.reason || ''

          if currreason
            # Do not overwrite the reason
            rxnr = %r/\A(?:securityerror|systemerror|undefined)\z/
            return false if currreason =~ rxnr
          else
            # Check the value of Diagnosic-Code: header with patterns
            return true if self.match(argvs.diagnosticcode)
          end
        end

      end
    end
  end
end



