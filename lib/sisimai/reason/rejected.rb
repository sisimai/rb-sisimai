module Sisimai
  module Reason
    # Sisimai::Reason::Rejected checks the bounce reason is "rejected" or not. This class is called
    # only Sisimai::Reason class.
    #
    # This is the error that a connection to destination server was rejected by a sender's email
    # address (envelope from). Sisimai set "rejected" to the reason of email bounce if the value of
    # Status: field in a bounce email is "5.1.8" or the connection has been rejected due to the
    # argument of SMTP MAIL command.
    #
    #   <kijitora@example.org>:
    #   Connected to 192.0.2.225 but sender was rejected.
    #   Remote host said: 550 5.7.1 <root@nijo.example.jp>... Access denied
    module Rejected
      class << self
        IsNot = [
          "5.1.0 address rejected",
          "ip address ",
          "recipient address rejected",
        ].freeze
        Index = [
          "access denied (in reply to mail from command)",
          "administrative prohibition",
          "all recipient addresses rejected : access denied",
          "backscatter protection detected an invalid or expired email address", # MDaemon
          "by non-member to a members-only list",
          "can't determine purported responsible address",
          "connections not accepted from servers without a valid sender domain",
          "denied by secumail valid-address-filter", # SecuMail
          "domain of sender address ",
          "email address is on senderfilterconfig list",
          "emetteur invalide",
          "empty email address",
          "empty envelope senders not allowed",
          "from: domain is invalid. please provide a valid from:",
          "fully qualified email address required",   # McAfee
          "invalid sender",
          "is not a registered gateway user",
          "mail from not owned by user",
          "mailfrom domain is listed in spamhaus",
          "null sender is not allowed",
          "returned mail not accepted here",
          "sending this from a different address or alias using the ",
          "sender is spammer",
          "sender not pre-approved",
          "sender domain is empty",
          "sender domain listed at ",
          "sender verify failed",     # Exim callout
          "server does not accept mail from",
          "spam reporting address",   # SendGrid|a message to an address has previously been marked as Spam by the recipient.
          "unroutable sender address",
          "you are not allowed to post to this mailing list",
          "your access to submit messages to this e-mail system has been rejected",
          "your email address has been blacklisted",  # MessageLabs
        ].freeze
        Pairs = [
          ["after end of data:", ".", " does not exist"],
          ["after mail from:", ".", " does not exist"],
          ["domain ", " is a dead domain"],
          ["email address ", "is not "],
          ["send", "blacklisted"],
          ["sender", " rejected"],
          ["sender is", " list"],
        ].freeze

        def text; return 'rejected'; end
        def description; return "Email rejected due to a sender's email address (envelope from)"; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return false if IsNot.any? { |a| argv1.include?(a) }
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # Rejected by the envelope sender address or not
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is rejected
        #                                   false: is not rejected by the sender
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'rejected'
          tempreason = Sisimai::SMTP::Status.name(argvs['deliverystatus'])
          return true if tempreason == 'rejected' # Delivery status code points "rejected".

          # Check the value of Diagnosic-Code: header with patterns
          issuedcode = argvs['diagnosticcode'].downcase
          thecommand = argvs['command'] || ''
          if thecommand == 'MAIL'
            # The session was rejected at 'MAIL FROM' command
            return true if match(issuedcode)

          elsif thecommand == 'DATA'
            # The session was rejected at 'DATA' command
            if tempreason != 'userunknown'
              # Except "userunknown"
              return true if match(issuedcode)
            end
          elsif %w[onhold undefined securityerror systemerror].include?(tempreason) || tempreason == ""
            # Try to match with message patterns when the temporary reason is "onhold", "undefined",
            # "securityerror", or "systemerror"
            return true if match(issuedcode)
          end
          return false
        end

      end
    end
  end
end



