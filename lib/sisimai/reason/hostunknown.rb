module Sisimai
  module Reason
    # This is the error that a domain part ( Right hand side of @ sign ) of a recipient's email
    # address does not exist. In many case, the domain part is misspelled, or the domain name has
    # been expired. Sisimai will set "hostunknown" to the reason of email bounce if the value of
    # Status: field in a bounce mail is "5.1.2".
    module HostUnknown
      class << self
        Index = [
          "all host address lookups failed", # Exim/transports/smtp.c:3524
          "couldn't find any host ",         # qmail-remote.c:78
          "dns server returned answer with no data",
          "domain is not reachable",
          "domain mentioned in email address is unknown",
          "domain must exist",
          "domain name not found",
          "host or domain name not found",
          "host unknown",
          "host unreachable",
          "illegal host/domain name found",
          "invalid domain name",                    # OpenSMTPD/smtpd/mta.c:976
          "mx records point to non-existent hosts", # Exim/routers/dnslookup.c:331
          "name or service not known",
          "no such domain",
          "recipient address rejected: unknown domain name",
          "responded with code nxdomain",
          "unknown host",
        ].freeze
        Pairs = [
          ["domain ", "not exist"],
          ["host ", " not found"],
          ["unrout", "able ", "address"],
        ].freeze

        def text; return 'hostunknown'; end
        def description; return "Delivery failed due to a domain part of a recipient's email address does not exist"; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        # @since v4.0.0
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # Whether the host is unknown or not
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [Boolean]               true:  is unknown host
        #                                   false: is not unknown host.
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true  if argvs['reason'] == 'hostunknown'
          return false if Sisimai::SMTP::Command::BeforeRCPT.include?(argvs['command'])

          issuedcode = argvs['diagnosticcode'].downcase || ''
          statuscode = argvs['deliverystatus'] || ''

          if Sisimai::SMTP::Status.name(statuscode) == 'hostunknown'
            # To prevent classifying DNS errors as "HostUnknown"
            require 'sisimai/reason/networkerror'
            return true if Sisimai::Reason::NetworkError.match(issuedcode) == false
          else
            # Status: 5.1.2
            # Diagnostic-Code: SMTP; 550 Host unknown
            return true if match(issuedcode)
          end

          return false
        end

      end
    end
  end
end

