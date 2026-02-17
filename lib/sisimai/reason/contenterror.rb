module Sisimai
  module Reason
    # Sisimai::Reason::ContentError checks the bounce reason is "contenterror" or not This class is
    # called only Sisimai::Reason class.
    #
    # This is the error that a destination mail server has rejected email due to header format of the
    # email like the following. Sisimai will set "contenterror" to the reason of email bounce if the
    # value of Status: field in a bounce email is "5.6.*".
    module ContentError
      class << self
        Index = [
          "charset not supported",
          "executable files are not allowed in compressed files",
          "header error",
          "header size exceeds maximum permitted",
          "illegal attachment on your message",
          "improper use of 8-bit data in message header",
          "it has a potentially executable attachment",
          "message contain invalid mime headers",
          "message contain improperly-formatted binary content",
          "message contain text that uses unnecessary base64 encoding",
          "message header size, or recipient list, exceeds policy limit",
          "message mime complexity exceeds the policy maximum",
          "message was blocked because its content presents a potential", # https://support.google.com/mail/answer/6590
          "routing loop detected -- too many received: headers",
          "we do not accept messages containing images or other attachments",
        ].freeze

        def text; return 'contenterror'; end
        def description; return 'Email rejected due to a header format of the email'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # Rejected email due to header format of the email
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  rejected due to content error
        #                                   false: is not content error
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          require 'sisimai/reason/spamdetected'
          return true  if argvs["reason"] == "blocked"
          return false if Sisimai::Reason::SpamDetected.true(argvs)
          return true  if Sisimai::SMTP::Status.name(argvs["deliverystatus"]) == "contenterror"
          return match(argvs["diagnosticcode"].downcase)
        end

      end
    end
  end
end

