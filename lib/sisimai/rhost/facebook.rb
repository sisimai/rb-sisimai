module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of find() method when the value of "rhost" of the object is "*.facebook.com". This class is
    # called only from Sisimai::Fact class.
    module Facebook
      class << self
        ErrorCodes = {
          # http://postmaster.facebook.com/response_codes
          # NOT TESTD EXCEPT RCP-P2
          "authfailure" => [
            "POL-P7",   # The message does not comply with Facebook's Domain Authentication requirements.
          ],
          "blocked" => [
            "POL-P1",   # Your mail server's IP Address is listed on the Spamhaus PBL.
            "POL-P2",   # Facebook will no longer accept mail from your mail server's IP Address.
            "POL-P3",   # Facebook is not accepting messages from your mail server. This will persist for 4 to 8 hours.
            "POL-P4",   # Facebook is not accepting messages from your mail server. This will persist for 24 to 48 hours.
            "POL-T1",   # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 1 to 2 hours.
            "POL-T2",   # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 4 to 8 hours.
            "POL-T3",   # Facebook is not accepting messages from your mail server, but they may be retried later. This will persist for 24 to 48 hours.
          ],
          "contenterror" => [
            "MSG-P2",   # The message contains an attachment type that Facebook does not accept.
          ],
          "emailtoolarge" => [
            "MSG-P1",   # The message exceeds Facebook's maximum allowed size.
            "INT-P2",   # The message exceeds Facebook's maximum allowed size.
          ],
          "filtered" => [
            "RCP-P2",   # The attempted recipient's preferences prevent messages from being delivered.
            "RCP-P3",   # The attempted recipient's privacy settings blocked the delivery.
          ],
          "mailboxfull" => [
            "INT-P7",   # The attempted recipient has exceeded their storage quota.
          ],
          "notcompliantrfc" => [
            "MSG-P3",   # The message contains multiple instances of a header field that can only be present once.
          ],
          "policyviolation" => [
            "POL-P8",   # The message does not comply with Facebook's abuse policies and will not be accepted.
          ],
          "ratelimited" => [
            "CON-T1",   # Facebook's mail server currently has too many connections open to allow another one.
            "CON-T2",   # Your mail server currently has too many connections open to Facebook's mail servers.
            "CON-T3",   # Your mail server has opened too many new connections to Facebook's mail servers in a short period of time.
            "CON-T4",   # Your mail server has exceeded the maximum number of recipients for its current connection.
            "MSG-T1",   # The number of recipients on the message exceeds Facebook's allowed maximum.
          ],
          "rejected" => [
            "DNS-P1",   # Your SMTP MAIL FROM domain does not exist.
            "DNS-P2",   # Your SMTP MAIL FROM domain does not have an MX record.
            "DNS-T1",   # Your SMTP MAIL FROM domain exists but does not currently resolve.
          ],
          "requireptr" => [
            "DNS-P3",   # Your mail server does not have a reverse DNS record.
            "DNS-T2",   # You mail server's reverse DNS record does not currently resolve.
          ],
          "spamdetected" => [
            "POL-P6",   # The message contains a url that has been blocked by Facebook.
          ],
          "suspend" => [
            "RCP-T4",   # The attempted recipient address is currently deactivated. The user may or may not reactivate it.
          ],
          "systemerror" => [
            "RCP-T1",   # The attempted recipient address is not currently available due to an internal system issue.
            "INT-Tx",   # These codes indicate a temporary issue internal to Facebook's system.
          ],
          "userunknown" => [
            "RCP-P1",   # The attempted recipient address does not exist.
            "INT-P1",   # The attempted recipient address does not exist.
            "INT-P3",   # The attempted recpient group address does not exist.
            "INT-P4",   # The attempted recipient address does not exist.
          ],
          "virusdetected" => [
            "POL-P5",   # The message contains a virus.
          ],
        }.freeze

        # Detect bounce reason from Facebook
        # @param    [Sisimai::Fact] argvs   Decoded email object
        # @return   [String]                The bounce reason for Facebook
        # @since v5.2.0
        def find(argvs)
          return "" if argvs["diagnosticcode"].empty?
          return "" if argvs["diagnosticcode"].include?("-") == false

          errorindex = argvs["diagnosticcode"].index("-")
          errorlabel = argvs["diagnosticcode"][errorindex - 3, 6]
          reasontext = ''

          ErrorCodes.each_key do |e|
            # The key is a bounce reason name
            next if ErrorCodes[e].none? { |a| errorlabel == a }
            reasontext = e
            break
          end

          return reasontext
        end

      end
    end
  end
end

