module Sisimai
  module Reason
    # Sisimai::Reason::SystemFull checks the bounce reason is "systemfull" or not. This class is called
    # only Sisimai::Reason class.
    #
    # This is the error that a destination mail server's disk (or spool) is full. Sisimai will set
    # systemfull to the reason of email bounce if the value of Status: field in a bounce email is
    # "4.3.1" or "5.3.1".
    module SystemFull
      class << self
        Index = [
          'mail system full',
          'requested mail action aborted: exceeded storage allocation',   # MS Exchange
        ].freeze

        def text; return 'systemfull'; end
        def description; return "Email rejected due to a destination mail server's disk is full"; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # The bounce reason is system full or not
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is system full
        #                                   false: is not system full
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs); return false; end

      end
    end
  end
end



