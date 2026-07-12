module Sisimai
  module Reason
    # Sisimai::Reason::SystemError checks the bounce reason is "SystemError" or not. This class is
    # called only Sisimai::Reason class. This is the error that an email has bounced due to system
    # error on the remote host such as LDAP connection failure or other internal system error.
    #
    #   <kijitora@example.net>:
    #   Unable to contact LDAP server. (#4.4.3)I'm not going to try again; this
    #   message has been in the queue too long.
    module SystemError
      class << self
        require 'sisimai/eb'
        Index = [
          "aliasing/forwarding loop broken",
          "automatic homedir creator crashed", # qmail-ldap-1.03-20040101.patch:19817 - 19866
          "can't create user output file",
          "cannot send e-mail to yourself",
          "could not load ",
          "delivery to file forbidden", # Exim/deliver.c:5614
          "delivery to pipe forbidden", # Exim/deliver.c:5624
          "input/output error",
          "interrupted system call",
          "it encountered an error while being processed",
          "it would create a mail loop",
          "ldap attribute",        # qmail-ldap-1.03-20040101.patch:19817 - 19866
          "ldap lookup",           # qmail-ldap-1.03-20040101.patch:19817 - 19866
          "ldap server",           # qmail-ldap-1.03-20040101.patch:19817 - 19866
          "lmtp error after ",     # Exim/transports/lmtp.c:186
          "local delivery failed", # Exim/transports/pipe.c:1156
          "loop back warning:",    # FML
          "loop was found in the mail exchanger",
          "loops back to myself",
          "mail transport unavailable",
          "may cause mail loop",   # FML
          "no such file or directory",
          "error while executing qmail-forward", # qmail-ldap-1.03-20040101.patch:19817 - 19866
          "queue file write error",
          "recipient deferred because there is no mdb",
          "remote server is misconfigured",
          "service currently unavailable",
          "several matches found in domino directory", # Donimo
          "temporary local problem",
          "timeout waiting for input",
          "too many results returned but needs to be unique", # qmail-ldap-1.03-20040101.patch:19817 - 19866
          "transaction failed ",
        ].freeze
        Pairs = [
          ["config", " error"],
          ["fml ", "has detected a loop condition so that"], # FML
          ["internal ", "error"],
          ["local ", "error"],
          ["proxy", "broken pipe"],
          ["unable to connect ", "daemon"],
        ].freeze

        def text; return Sisimai::Eb::RePROC; end
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



