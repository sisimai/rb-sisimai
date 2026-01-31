module Sisimai
  module Reason
    # Sisimai::Reason::SystemError checks the bounce reason is "systemerror" or not. This class is
    # called only Sisimai::Reason class. This is the error that an email has bounced due to system
    # error on the remote host such as LDAP connection failure or other internal system error.
    #
    #   <kijitora@example.net>:
    #   Unable to contact LDAP server. (#4.4.3)I'm not going to try again; this
    #   message has been in the queue too long.
    module SystemError
      class << self
        Index = [
          "aliasing/forwarding loop broken",
          "can't create user output file",
          "cannot send e-mail to yourself",
          "could not load ",
          "interrupted system call",
          "it encountered an error while being processed",
          "it would create a mail loop",
          "loop was found in the mail exchanger",
          "loops back to myself",
          "queue file write error",
          "recipient deferred because there is no mdb",
          "remote server is misconfigured",
          "service currently unavailable",
          "temporary local problem",
          "timeout waiting for input",
          "transaction failed ",
        ].freeze
        Pairs = [
          ["config", " error"],
          ["internal ", "error"],
          ["local ", "error"],
          ["unable to connect ", "daemon"],
        ].freeze

        def text; return 'systemerror'; end
        def description; return 'Email returned due to system error on the remote host'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # The bounce reason is system error or not
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is system error
        #                                   false: is not system error
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs); return false; end

      end
    end
  end
end



