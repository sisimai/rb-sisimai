module Sisimai
  module Reason
    # Sisimai::Reason::BadReputation checks the bounce reason is "badreputation" or not. This class
    # is called only Sisimai::Reason class.
    #
    # This is the error that an email rejected due to a reputation score of the sender IP address.
    #
    #   Action: failed
    #   Status: 5.7.1
    #   Remote-MTA: dns; gmail-smtp-in.l.google.com
    #   Diagnostic-Code: smtp; 550-5.7.1 [192.0.2.22] Our system has detected that this message is
    #                    likely suspicious due to the very low reputation of the sending IP address.
    #                    To best protect our users from spam, the message has been blocked. Please
    #                    visit https://support.google.com/mail/answer/188131 for more information.
    module BadReputation
      class << self
        Index = [
          'a poor email reputation score',
          'has been temporarily rate limited due to ip reputation',
          'ip/domain reputation problems',
          'likely suspicious due to the very low reputation',
          'temporarily deferred due to unexpected volume or user complaints', # Yahoo Inc.
          "the sending mta's poor reputation",
        ].freeze
        def text; return 'badreputation'; end
        def description; return 'Email rejected due to an IP address reputation'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # The bounce reason is "badreputation" or not
        # @param    [Sisimai::Fact] argvs Object to be detected the reason
        # @return   [True,False]          true:  is BadReputation
        #                                 false: is not BadReputation
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true if argvs['reason'] == 'badreputation'
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end

