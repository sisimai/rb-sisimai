module Sisimai
  module Reason
    # Sisimai::Reason::NotCompliantRFC checks the bounce reason is "NotCompliantRFC" or not. This
    # class is called only from Sisimai::Reason class.
    #
    # This is the error that an email is not compliant RFC 5322 or other email related RFCs. For
    # example, there are multiple "Subject" headers in the email.
    module NotCompliantRFC
      class << self
        require 'sisimai/eb'
        Index = [
          "duplicate header",
          "duplicated message-id",
          "message is not rfc 5322 compliant",
          "multiple addresses in from: header are not accepted",
          "rfc 1035 violation",
          "https://support.google.com/mail/?p=rfcmessagenoncompliant",
        ].freeze

        def text; return Sisimai::Eb::ReNRFC; end
        def description; return 'Email rejected due to non-compliance with RFC'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # Whether the email is RFC compliant or not
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:   RFC comliant
        #                                   false: Is not RFC compliant
        # @see http://www.ietf.org/rfc/rfc5322.txt
        def true(argvs)
          return true if argvs['reason'] == Sisimai::Eb::ReNRFC
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end

