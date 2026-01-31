module Sisimai
  module Reason
    # Sisimai::Reason::Expired checks the bounce reason is "expired" or not. This class is called only
    # Sisimai::Reason class.
    #
    # This is the error that delivery time has expired due to connection failure or network error and
    # the message you sent has been in the queue for long time.
    module Expired
      class << self
        Index = [
          "connection timed out",
          "could not find a gateway for",
          "delivery attempts will continue to be",
          "failed to deliver to domain ",
          "have been failing for a long time",
          "has been delayed",
          "it has not been collected after",
          "message could not be delivered for more than",
          "message expired, ",
          "message has been in the queue too long",
          "message timed out",
          "server did not respond",
          "unable to deliver message after multiple retries",
        ].freeze
        Pairs = [
          ["could not be delivered for", " days"],
          ["delivery ", "expired"],
          ["not", "reach", "period"],
        ].freeze

        def text; return 'expired'; end
        def description; return 'Delivery time has expired due to a connection failure'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # Delivery expired due to connection failure or network error
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is expired
        #                                   false: is not expired
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs); return false; end

      end
    end
  end
end


