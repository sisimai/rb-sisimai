module Sisimai
  module Reason
    # Sisimai::Reason::PolicyViolation checks the bounce reason is "policyviolation"
    # or not. This class is called only Sisimai::Reason class.
    #
    # This is the error that a policy violation was detected on a destination mail
    # host. When a header content or a format of the original message violates
    # security policies, or multiple addresses exist in the From: header, Sisimai
    # will set "policyviolation".
    #
    #   Action: failed
    #   Status: 5.7.9
    #   Remote-MTA: DNS; mx.example.co.jp
    #   Diagnostic-Code: SMTP; 554 5.7.9 Header error
    #
    module PolicyViolation
      # Imported from p5-Sisimail/lib/Sisimai/Reason/PolicyViolation.pm
      class << self
        Index = [
          'because the recipient is not accepting mail with ',    # AOL Phoenix
          'closed mailing list',
          'denied by policy',
          'email not accepted for policy reasons',
          # http://kb.mimecast.com/Mimecast_Knowledge_Base/Administration_Console/Monitoring/Mimecast_SMTP_Error_Codes#554
          'email rejected due to security policies',
          'header are not accepted',
          'header error',
          'local policy violation',
          'message given low priority',
          'message not accepted for policy reasons',
          'messages with multiple addresses',
          'rejected for policy reasons',
          'protocol violation',
          'the email address used to send your message is not subscribed to this group',
          'you have exceeded the allowable number of posts without solving a captcha',
          'you have exceeded the the allowable number of posts without solving a captcha',
        ]

        def text; return 'policyviolation'; end
        def description; return 'Email rejected due to policy violation on a destination host'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        # @since 4.22.0
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # The bounce reason is security error or not
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: is policy violation
        #                                   false: is not policy violation
        # @since 4.22.0
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs)
          return nil
        end

      end
    end
  end
end

