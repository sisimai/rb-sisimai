module Sisimai
  module Reason
    # Sisimai::Reason::PolicyViolation checks the bounce reason is "policyviolation" or not. This class
    # is called only Sisimai::Reason class.
    #
    # This is the error that a policy violation was detected on a destination mail host. When a header
    # content or a format of the original message violates security policies, or multiple addresses
    # exist in the From: header, Sisimai will set "policyviolation".
    #
    #   Status: 5.7.0
    #   Remote-MTA: DNS; gmail-smtp-in.l.google.com
    #   Diagnostic-Code: SMTP; 552-5.7.0 Our system detected an illegal attachment on your message. Please
    #   Last-Attempt-Date: Tue, 28 Apr 2009 11:02:45 +0900 (JST)
    #
    module PolicyViolation
      class << self
        Index = [
          "because the recipient is not accepting mail with ",    # AOL Phoenix
          "closed mailing list",
          "delivery not authorized, message refused",
          "denied by policy",
          # http://kb.mimecast.com/Mimecast_Knowledge_Base/Administration_Console/Monitoring/Mimecast_SMTP_Error_Codes#554
          "email rejected due to security policies",
          "for policy reasons",
          "local policy violation",
          "message bounced due to organizational settings",
          "message given low priority",
          "message was rejected by organization policy",
          "protocol violation",
          "support.google.com/a/answer/172179",
          "you're using a mass mailer",
        ].freeze

        def text; return 'policyviolation'; end
        def description; return 'Email rejected due to policy violation on a destination host'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        # @since 4.22.0
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # The bounce reason is "policyviolation" or not
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is policy violation
        #                                   false: is not policy violation
        # @since 4.22.0
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true  if argvs['reason'] == 'policyviolation'
          return false if argvs['command'] != '' && argvs['command'] != 'DATA'
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end

