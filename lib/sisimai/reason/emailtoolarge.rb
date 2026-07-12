module Sisimai
  module Reason
    # This is the error that a sent email size is too big for a destination mail server. In many
    # case, There are many attachment files with email, or the file size is too large. Sisimai will
    # set "EmailTooLarge" to the reason of email bounce if the value of Status: field in a bounce
    # email is "5.2.3" or "5.3.4".
    module EmailTooLarge
      class << self
        require 'sisimai/eb'
        Index = [
          "exceeds the maximum size ",
          "line limit exceeded",
          "message too large",
          "size limit",
          "taille limite du message atteinte",
        ].freeze
        Pairs = [
          ["exceeded", "message size"],
          ["message ", "exceeds ", "limit"],
          ["message ", "size", "exceed"],
          ["message ", "too", "big"],
        ].freeze

        def text; return Sisimai::Eb::ReSIZE; end
        def description; return 'Email rejected due to an email size is too big for a destination mail server'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # The message size is too big for the remote host
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is too big message size
        #                                   false: is not big
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == Sisimai::Eb::ReSIZE

          statuscode = argvs['deliverystatus'] || ''
          tempreason = Sisimai::SMTP::Status.name(statuscode)

          # Delivery status code points "EmailTooLarge".
          # Status: 5.3.4
          # Diagnostic-Code: SMTP; 552 5.3.4 Error: message file too big
          #
          # Status: 5.2.3
          # Deiagnostic-Code: Message length exceeds administrative limit
          return true if tempreason == Sisimai::Eb::ReSIZE
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end

