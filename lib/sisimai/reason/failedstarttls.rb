module Sisimai
  module Reason
    # Sisimai::Reason::FailedSTARTTLS checks the bounce reason is "failedstarttls" or not.
    # This class is called only Sisimai::Reason class.
    module FailedSTARTTLS
      class << self
        # Email delivery failed due to STARTTLS related problem
        Index = [
          'starttls is required to send mail',
          'tls required but not supported',   # SendGrid:the recipient mailserver does not support TLS or have a valid certificate
        ].freeze

        def text; return 'failedstarttls'; end
        def description; return "Email delivery failed due to STARTTLS related problem"; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # Email delivery failed due to STARTTLS related problem
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  FailedSTARTTLS
        #                                   false: Not FailedSTARTTLS
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs["reason"] == "failedstarttls" || argvs["command"] == "STARTTLS"
          return true if [523, 524, 538].index(argvs["replycode"].to_i)
          return match(argvs["diagnosticcode"].downcase)
        end

      end
    end
  end
end

