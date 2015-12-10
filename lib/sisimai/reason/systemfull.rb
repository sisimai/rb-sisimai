module Sisimai
  module Reason
    # Sisimai::Reason::SystemFull checks the bounce reason is "systemfull" or
    # not. This class is called only Sisimai::Reason class.
    #
    # This is the error that a destination mail server's disk (or spool) is full.
    # Sisimai will set C<systemfull> to the reason of email bounce if the value
    # of Status: field in a bounce email is "4.3.1" or "5.3.1".
    module Filtered
      # Imported from p5-Sisimail/lib/Sisimai/Reason/SystemFull.pm
      class << self
        def text; return 'systemfull'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r{(?:
             mail[ ]system[ ]full
            |requested[ ]mail[ ]action[ ]aborted:[ ]exceeded[ ]storage[ ]allocation # MS Exchange
            )
          }ix

          return true if argv1 =~ regex
          return false
        end

        def true; return nil; end

      end
    end
  end
end



