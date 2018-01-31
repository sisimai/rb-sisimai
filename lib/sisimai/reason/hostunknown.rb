module Sisimai
  module Reason
    # This is the error that a domain part ( Right hand side of @ sign ) of a
    # recipient's email address does not exist. In many case, the domain part
    # is misspelled, or the domain name has been expired.
    # Sisimai will set "hostunknown" to the reason of email bounce if the value
    # of Status: field in a bounce mail is "5.1.2".
    module HostUnknown
      # Imported from p5-Sisimail/lib/Sisimai/Reason/HostUnknown.pm
      class << self
        def text; return 'hostunknown'; end
        def description; return "Delivery failed due to a domain part of a recipient's email address does not exist"; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true:  Matched
        # @since v4.0.0
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             domain[ ](?:
               does[ ]not[ ]exist
              |is[ ]not[ ]reachable
              |must[ ]exist
              )
            |host[ ](?:
               or[ ]domain[ ]name[ ]not[ ]found
              |unknown
              |unreachable
              )
            |Mail[ ]domain[ ]mentioned[ ]in[ ]email[ ]address[ ]is[ ]unknown
            |name[ ]or[ ]service[ ]not[ ]known
            |no[ ]such[ ]domain
            |recipient[ ](?:
               address[ ]rejected:[ ]unknown[ ]domain[ ]name
              |domain[ ]must[ ]exist
              )
            |The[ ]account[ ]or[ ]domain[ ]may[ ]not[ ]exist
            |unknown[ ]host
            |Unrouteable[ ]address
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        # Whether the host is unknown or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is unknown host
        #                                   false: is not unknown host.
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return true if argvs.reason == 'hostunknown'

          require 'sisimai/smtp/status'
          diagnostic = argvs.diagnosticcode || ''
          statuscode = argvs.deliverystatus || ''

          if Sisimai::SMTP::Status.name(statuscode) == 'hostunknown'
            # Status: 5.1.2
            # Diagnostic-Code: SMTP; 550 Host unknown
            require 'sisimai/reason/networkerror'
            return true unless Sisimai::Reason::NetworkError.match(diagnostic)
          else
            # Check the value of Diagnosic-Code: header with patterns
            return true if match(diagnostic)
          end

          return false
        end

      end
    end
  end
end

