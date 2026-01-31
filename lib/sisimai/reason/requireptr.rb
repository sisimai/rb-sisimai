module Sisimai
  module Reason
    # Sisimai::Reason::RequirePTR checks the bounce reason is "requireptr" or not. This class is
    # called only from Sisimai::Reason class. This is the error that SMTP connection was rejected
    # due to missing PTR record or having invalid PTR record at the source IP address used for the
    # SMTP connection.
    module RequirePTR
      class << self
        Index = [
          "cannot find your hostname",
          "cannot resolve your address.",
          "corresponding forward dns entry does not point to the sending ip", # Google
          "ip name lookup failed",
          "no matches to nameserver query",
          "sender ip reverse lookup rejected",
          "unresolvable relay host name",
        ].freeze
        Pairs = [
          ["domain "," mismatches client ip"],
          ["domain name verification on your ip address ", "failed"],
          ["dns lookup failure: ", " try again later"],
          ["ptr", "record"],
          ["reverse", " dns"],
          ["server access ", " forbidden by invalid rdns record of your mail server"],
          ["service permits ", " unverifyable sending ips"],
        ].freeze

        def text; return 'requireptr'; end
        def description; return 'Email rejected due to missing PTR record or having invalid PTR record'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # Check the email rejected due to missing PTR record or having invalid PTR record OR not
        # @param    [Hash] argvs  Hash to be detected the value of reason
        # @return   [Boolean]     true:  is missing PTR or invalid PTR
        #                         false: is not blocked due to missing PTR record
        # @see      http://www.ietf.org/rfc/rfc5322.txt
        def true(argvs)
          return true if argvs['reason'] == 'requireptr'
          return true if Sisimai::SMTP::Status.name(argvs['deliverystatus']) == 'requireptr'
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end

