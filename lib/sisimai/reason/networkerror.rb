module Sisimai
  module Reason
    # Sisimai::Reason::NetworkError checks the bounce reason is "networkerror" or not. This class is
    # called only Sisimai::Reason class. This is the error that SMTP connection failed due to DNS
    # look up failure or other network problems.
    #
    #   A message is delayed for more than 10 minutes for the following
    #   list of recipients:
    #
    #   kijitora@neko.example.jp: Network error on destination MXs
    module NetworkError
      class << self
        Index = [
          "could not connect and send the mail to",
          "dns records for the destination computer could not be found",
          "host is unreachable",
          "host name lookup failure",
          "host not found, try again",
          "maximum forwarding loop count exceeded",
          "no route to host",
          "too many hops",
          "unable to resolve route ",
          "unrouteable mail domain",
        ].freeze
        Pairs = [
          ["malformed", "name server reply"],
          ["mail ", "loop"],
          ["message ", "loop"],
        ].freeze

        def text; return 'networkerror'; end
        def description; return 'SMTP connection failed due to DNS look up failure or other network problems'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # The bounce reason is network error or not
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is network error
        #                                   false: is not network error
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(_argvs); return false; end

      end
    end
  end
end



