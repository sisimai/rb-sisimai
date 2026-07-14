module Sisimai
  module Reason
    # Sisimai::Reason::NetworkError checks the bounce reason is "NetworkError" or not. This class is
    # called only Sisimai::Reason class. This is the error that SMTP connection failed due to DNS
    # look up failure or other network problems.
    #
    #   A message is delayed for more than 10 minutes for the following
    #   list of recipients:
    #
    #   kijitora@neko.example.jp: Network error on destination MXs
    module NetworkError
      class << self
        require 'sisimai/eb'
        Index = [
          "address family mismatch on destination mxs", # OpenSMTPD/smtpd/mta.c
          "all routes to destination blocked",          # OpenSMTPD/smtpd/mta.c
          "bad dns lookup error code",                  # OpenSMTPD/smtpd/mta.c
          "could not connect and send the mail to",
          "could not contact dns servers",
          "could not retrieve source address",          # OpenSMTPD/smtpd/mta.c
          "dns records for the destination computer could not be found",
          "establish an smtp connection",
          "exceeded maximum hop count",                 # Courier
          "host is unreachable",
          "host name lookup failure",
          "host not found, try again",
          "listed as a best-preference mx",
          "loop detected",                              # OpenSMTPD/smtpd/mta.c
          "maximum forwarding loop count exceeded",
          "network error on destination mxs",           # OpenSMTPD/smtpd/mta.c
          "no relevant answers",
          "temporary failure in mx lookup",             # OpenSMTPD/smtpd/mta.c
          "too many hops",
          "unable to resolve route ",
          "unrouteable mail domain",
        ].freeze
        Pairs = [
          ["malformed", "name server reply"],
          ["mail ", "loop"],
          ["message ", "loop"],
          ["no ", "route to"],
        ].freeze

        def text; return Sisimai::Eb::ReINET; end
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



