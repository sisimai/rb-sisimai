module Sisimai
  module Reason
    # Sisimai::Reason::Suppressed checks the bounce reason is "suppressed" or not. This class is called
    # only Sisimai::Reason class.
    #
    # This is the error that the recipient adddress is listed in the suppression list of the relay
    # server, and was not delivered.
    module Suppressed
      class << self
        def text; return 'suppressed'; end
        def description; return "Email was not delivered due to being listed in the suppression list of MTA"; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1); return false; end

        # Whether the address is listed in the suppression list
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  The address is listed in the suppression list
        #                                   false: is not listed in the suppression list
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'suppressed'
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end

