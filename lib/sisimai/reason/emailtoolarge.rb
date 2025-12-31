module Sisimai
  module Reason
    # This is the error that a sent email size is too big for a destination mail server. In many
    # case, There are many attachment files with email, or the file size is too large. Sisimai will
    # set "emailtoolarge" to the reason of email bounce if the value of Status: field in a bounce
    # email is "5.2.3" or "5.3.4".
    module EmailTooLarge
      class << self
        Index = [
          'exceeded maximum inbound message size',
          'exceeded the maximum incoming message size',
          'line limit exceeded',
          'max message size exceeded',
          'message file too big',
          'message header size exceeds limit',
          'message length exceeds administrative limit',
          'message size exceeds fixed limit',
          'message size exceeds fixed maximum message size',
          'message size exceeds maximum value',
          'message too big',
          'message too large',
          'size limit',
          'taille limite du message atteinte',
        ].freeze

        def text; return 'emailtoolarge'; end
        def description; return 'Email rejected due to an email size is too big for a destination mail server'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # The message size is too big for the remote host
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is too big message size
        #                                   false: is not big
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'emailtoolarge'

          statuscode = argvs['deliverystatus'] || ''
          tempreason = Sisimai::SMTP::Status.name(statuscode)

          # Delivery status code points "emailtoolarge".
          # Status: 5.3.4
          # Diagnostic-Code: SMTP; 552 5.3.4 Error: message file too big
          #
          # Status: 5.2.3
          # Deiagnostic-Code: Message length exceeds administrative limit
          return true if tempreason == 'emailtoolarge'
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end

