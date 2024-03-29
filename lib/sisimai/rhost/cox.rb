module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of get() method when the value of "destination" of the object is "charter.net". This class is
    # called only Sisimai::Fact class.
    module Cox
      class << self
        ErrorCodes = {
          # https://www.cox.com/residential/support/email-error-codes.html
          'CXBL'      => 'blocked',       # The sending IP address has been blocked by Cox due to exhibiting spam-like behavior.
          'CXTHRT'    => 'securityerror', # Email sending limited due to suspicious account activity.
          'CXMJ'      => 'securityerror', # Email sending blocked due to suspicious account activity on primary Cox account.
          'CXDNS'     => 'blocked',       # There was an issue with the connecting IP address Domain Name System (DNS).
          'CXSNDR'    => 'rejected',      # There was a problem with the sender's domain.
          'CXSMTP'    => 'rejected',      # Your email wasn't delivered because Cox was unable to verify that it came from a legitimate email sender.
          'CXCNCT'    => 'toomanyconn',   # There is a limit to the number of concurrent SMTP connections per IP address
          'CXMXRT'    => 'toomanyconn',   # The email sender has exceeded the maximum number of sent email allowed.
          'CDRBL'     => 'blocked',       # The sending IP address has been temporarily blocked by Cox due to exhibiting spam-like behavior.
          'IPBL0001'  => 'blocked',       # The sending IP address is listed in the Spamhaus Zen DNSBL.
          'IPBL0010'  => 'blocked',       # The sending IP is listed in the Return Path DNSBL.
          'IPBL0100'  => 'blocked',       # The sending IP is listed in the Invaluement ivmSIP DNSBL.
          'IPBL0011'  => 'blocked',       # The sending IP is in the Spamhaus Zen and Return Path DNSBLs.
          'IPBL0101'  => 'blocked',       # The sending IP is in the Spamhaus Zen and Invaluement ivmSIP DNSBLs.
          'IPBL0110'  => 'blocked',       # The sending IP is in the Return Path and Invaluement ivmSIP DNSBLs.
          'IPBL0111'  => 'blocked',       # The sending IP is in the Spamhaus Zen, Return Path and Invaluement ivmSIP DNSBLs.
          'IPBL1000'  => 'blocked',       # The sending IP address is listed on a CSI blacklist. You can check your status on the CSI website.
          'IPBL1001'  => 'blocked',       # The sending IP is listed in the Cloudmark CSI and Spamhaus Zen DNSBLs.
          'IPBL1010'  => 'blocked',       # The sending IP is listed in the Cloudmark CSI and Return Path DNSBLs.
          'IPBL1011'  => 'blocked',       # The sending IP is in the Cloudmark CSI, Spamhaus Zen and Return Path DNSBLs.
          'IPBL1100'  => 'blocked',       # The sending IP is listed in the Cloudmark CSI and Invaluement ivmSIP DNSBLs.
          'IPBL1101'  => 'blocked',       # The sending IP is in the Cloudmark CSI, Spamhaus Zen and Invaluement IVMsip DNSBLs.
          'IPBL1110'  => 'blocked',       # The sending IP is in the Cloudmark CSI, Return Path and Invaluement ivmSIP DNSBLs.
          'IPBL1111'  => 'blocked',       # The sending IP is in the Cloudmark CSI, Spamhaus Zen, Return Path and Invaluement ivmSIP DNSBLs.
          'IPBL00001' => 'blocked',       # The sending IP address is listed on a Spamhaus blacklist. Check your status at Spamhaus.
          'URLBL011'  => 'spamdetected',  # A URL within the body of the message was found on blocklists SURBL and Spamhaus DBL.
          'URLBL101'  => 'spamdetected',  # A URL within the body of the message was found on blocklists SURBL and ivmURI.
          'URLBL110'  => 'spamdetected',  # A URL within the body of the message was found on blocklists Spamhaus DBL and ivmURI.
          'URLBL1001' => 'spamdetected',  # The URL is listed on a Spamhaus blacklist. Check your status at Spamhaus.
        }.freeze
        MessagesOf = {
          'blocked' => [
            # Cox requires that all connecting email servers contain valid reverse DNS PTR records.
            'rejected - no rDNS',
            # An email client has repeatedly sent bad commands or invalid passwords resulting in a three-hour block of the client's IP address.
            'cox too many bad commands from',
            # The reverse DNS check of the sending server IP address has failed.
            'DNS check failure - try again later',
            # The sending IP address has exceeded the threshold of invalid recipients and has been blocked.
            'Too many invalid recipients',
          ],
          'notaccept' => [
            # Our systems are experiencing an issue which is causing a temporary inability to accept new email.
            'ESMTP server temporarily not available',
          ],
          'policyviolation' => [
            # The sending server has attempted to communicate too soon within the SMTP transaction
            'ESMTP no data before greeting',
            # The message has been rejected because it contains an attachment with one of the following prohibited
            # file types, which commonly contain viruses: .shb, .shs, .vbe, .vbs, .wsc, .wsf, .wsh, .pif, .msc,
            # .msi, .msp, .reg, .sct, .bat, .chm, .isp, .cpl, .js, .jse, .scr, .exe.
            'attachment extension is forbidden',
          ],
          'rejected' => [
            # Cox requires that all sender domains resolve to a valid MX or A-record within DNS.
            'sender rejected',
          ],
          'toomanyconn' => [
            # The sending IP address has exceeded the five maximum concurrent connection limit.
            'too many sessions from',
            # The SMTP connection has exceeded the 100 email message threshold and was disconnected.
            'requested action aborted: try again later',
            # The sending IP address has exceeded one of these rate limits and has been temporarily blocked.
            'Message threshold exceeded',
          ],
          'userunknown' => [
            'recipient rejected', # The intended recipient is not a valid Cox Email account.
          ],
        }.freeze

        # Detect bounce reason from https://cox.com/
        # @param    [Sisimai::Fact] argvs   Parsed email object
        # @return   [String, Nil]           The bounce reason at Cox
        # @since v4.25.8
        def get(argvs)
          statusmesg = argvs['diagnosticcode']
          codenumber = 0

          if cv = statusmesg.match(/AUP#([0-9A-Z]+)/)
            # Capture the numeric part of the error code
            codenumber = cv[1]
          end
          reasontext = ErrorCodes[codenumber] || ''

          if reasontext.empty?
            # The error code was not found in ErrorCodes
            MessagesOf.each_key do |e|
              # Try to find with each error message defined in MessagesOf
              next unless MessagesOf[e].any? { |a| statusmesg.include?(a) }
              reasontext = e
              break
            end
          end

          return reasontext
        end

      end
    end
  end
end

