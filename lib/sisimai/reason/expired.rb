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
          "delay reason: ",    # Exim/deliver.c:7459
          "delivery attempts will continue to be",
          "envelope expired",  # OpenSMTPD/smtpd/queue.c:221
          "failed to deliver to domain ",
          "frozen on arrival", # Exim/receive.c:4022
          "has been delayed",
          "has been frozen",   # Exim/deliver.c:7586
          "have been failing for a long time", # Exim/smtp.c:3508
          "host not reachable",
          "it has not been collected after",
          "message could not be delivered for more than",
          "message expired, ",
          "message has been in the queue too long",
          "message was not delivered within ",
          "message timed out",
          "retry timeout exceeded",             # Exim/retry.c:902
          "server did not accept our requests to connect",
          "server did not respond",
          "unable to deliver message after multiple retries",
        ].freeze
        Pairs = [
          ["could not be delivered for", " days"],
          ["could not deliver for the last", "second"],
          ["delivery ", "expired"],
          ["delivery ", "delayed"],
          ["exceed", "time", "out"],
          ["not", "reach", "period"], # Exim/smtp.c:3508
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


