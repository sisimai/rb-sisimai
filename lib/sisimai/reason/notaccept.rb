module Sisimai
  module Reason
    # Sisimai::Reason::NotAccept checks the bounce reason is "NotAccept" or not. This class is
    # called only Sisimai::Reason class.
    #
    # This is the error that a destination mail server does ( or can ) not accept any email. In
    # many case, the server is high load or under the maintenance. Sisimai will set "NotAccept" to
    # the reason of email bounce if the value of Status: field in a bounce email is "5.3.2" or the
    # value of SMTP reply code is 556.
    module NotAccept
      require 'sisimai/eb'
      class << self
        # Destination mail server does not accept any message
        Index = [
          "destination seem to reject all mails", # OpenSMTPD/smtp/mta.c
          "does not accept mail",                 # Sendmail, iCloud
          "mail receiving disabled",
          "mx or srv record indicated no smtp ",  # Exim/routers/dnslookup.c:328
          "name server: .: host not found",       # Sendmail
          "no host found for existing smtp ",     # Exim/transports/smtp.c:3502
          "no route for current request",
          "null mx",
        ].freeze
        Pairs = [
          ["no mx ", "found for "], # OpenSMTPD/smtp/mta.c
        ].freeze

        def text; return Sisimai::Eb::Re00MX; end
        def description; return 'Delivery failed due to a destination mail server does not accept any email'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [Boolean]       false: Did not match, true: Matched
        def match(argv1)
          return false if argv1.nil? || argv1.empty?
          return true  if Index.any? { |a| argv1.include?(a) }
          return true  if Pairs.any? { |a| Sisimai::String.aligned(argv1, a) }
          return false
        end

        # Remote host does not accept any message
        # @param    [Sisimai::Fact] argvs   Object to be detected the reason
        # @return   [True,False]            true: Not accept
        #                                   false: Accept
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return true  if argvs['reason'] == Sisimai::Eb::Re00MX
          return true  if [521, 556].index(argvs['replycode'].to_i) # SMTP Reply Code is 554 or 556
          return false if Sisimai::SMTP::Command::BeforeRCPT.include?(argvs['command'])
          return match(argvs['diagnosticcode'].downcase)
        end

      end
    end
  end
end



