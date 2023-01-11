module Sisimai
  module Reason
    # Sisimai::Reason::Speeding checks the bounce reason is "speeding" or not. This class is called
    # only Sisimai::Reason class. This is the error that a connection rejected due to exceeding a
    # rate limit or sending too fast.
    module Speeding
      class << self
        Index = [
          'please try again slower',
          'receiving mail at a rate that prevents additional messages from being delivered',
        ].freeze

        def text; return 'speeding'; end
        def description; return 'Rejected due to exceeding a rate limit or sending too fast'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          return true if Index.any? { |a| argv1.include?(a) }
          return false
        end

        # Speeding or not
        # @param    [Sisimai::Fact] argvs Object to be detected the reason
        # @return   [True,False]          true: is speeding
        #                                 false: is not speeding
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil  if argvs['deliverystatus'].empty?
          return true if argvs['reason'] == 'speeding'

          # Action: failed
          # Status: 4.7.1
          # Remote-MTA: dns; smtp.example.jp
          # Diagnostic-Code: smtp; 451 4.7.1 <mx.example.org[192.0.2.2]>: Client host rejected:
          #                  Please try again slower
          return true if match(argvs['diagnosticcode'].downcase)
          return false
        end

      end
    end
  end
end

