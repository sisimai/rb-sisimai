module Sisimai
  module Reason
    # Sisimai::Reason::AuthFailure checks the bounce reason is "authfailure" or not. This class is
    # called only Sisimai::Reason class.
    #
    # This is the error that an authenticaion failure related to SPF, DKIM, or DMARC was detected
    # on a destination mail host. 
    #
    # Action: failed
    # Status: 5.7.1
    # Remote-MTA: dns; smtp.example.com
    # Diagnostic-Code: smtp; 550 5.7.1 Email rejected per DMARC policy for example.org
    module AuthFailure
      class << self
        Index = [
          "//spf.pobox.com",
          "5322.From address doesn't meet the authentication requirements",
          "bad spf records for",
          "dmarc policy",
          "doesn't meet the required authentication level",
          "please inspect your spf settings",
          "sender policy framework",
          "spf check: fail",
        ].freeze
        Pairs = [
          [" is not allowed to send mail.", "_401"],
          ["is not allowed to send from <", " per it's spf record"],
        ].freeze

        def text; return 'authfailure'; end
        def description; return 'Email rejected due to SPF, DKIM, DMARC failure'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # The bounce reason is "authfailure" or not
        # @param    [Sisimai::Fact] argvs Object to be detected the reason
        # @return   [Boolean]             true: is AuthFailure, false: is not AuthFailure
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return false if argvs['deliverystatus'].empty?
          return true  if argvs['reason'] == 'authfailure'
          return true  if Sisimai::SMTP::Status.name(argvs['deliverystatus']) == 'authfailure'
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end

