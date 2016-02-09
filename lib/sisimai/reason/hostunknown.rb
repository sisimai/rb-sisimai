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

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?>
             domain[ ](?:
               does[ ]not[ ]exist
              |must[ ]exist
              |is[ ]not[ ]reachable
              )
            |host[ ](?:
               or[ ]domain[ ]name[ ]not[ ]found
              |unknown
              |unreachable
              )
            |name[ ]or[ ]service[ ]not[ ]known
            |no[ ]such[ ]domain
            |recipient[ ](?:
            address[ ]rejected:[ ]unknown[ ]domain[ ]name
              domain[ ]must[ ]exist
              )
            |unknown[ ]host
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
          return true if argvs.reason == Sisimai::Reason::HostUnknown.text

          require 'sisimai/smtp/status'
          diagnostic = argvs.diagnosticcode || ''
          statuscode = argvs.deliverystatus || ''
          tempreason = Sisimai::SMTP::Status.name(statuscode)
          reasontext = Sisimai::Reason::HostUnknown.text
          v = false

          if tempreason == reasontext
            # Status: 5.1.2
            # Diagnostic-Code: SMTP; 550 Host unknown
            v = true
          else
            # Check the value of Diagnosic-Code: header with patterns
            v = true if Sisimai::Reason::HostUnknown.match(diagnostic)
          end

          return v
        end

      end
    end
  end
end



