module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of get() method when the value of "destination" of the object is "mail.icloud.com" or "apple.com".
    # This class is called only Sisimai::Fact class.
    module Apple
      class << self
        MessagesOf = {
          'authfailure' => [
            # - 554 5.7.1 Your message was rejected due to example.jp's DMARC policy.
            #   See https://support.apple.com/en-us/HT204137 for
            # - 554 5.7.1 [HME1] This message was blocked for failing both SPF and DKIM authentication
            #   checks. See https://support.apple.com/en-us/HT204137 for mailing best practices
            's dmarc policy',
            'blocked for failing both spf and dkim autentication checks',
          ],
          'blocked' => [
            # - 550 5.7.0 Blocked - see https://support.proofpoint.com/dnsbl-lookup.cgi?ip=192.0.1.2
            # - 550 5.7.1 Your email was rejected due to having a domain present in the Spamhaus
            #   DBL -- see https://www.spamhaus.org/dbl/
            # - 550 5.7.1 Mail from IP 192.0.2.1 was rejected due to listing in Spamhaus SBL.
            #   For details please see http://www.spamhaus.org/query/bl?ip=x.x.x.x
            # - 554 ****-smtpin001.me.com ESMTP not accepting connections
            'rejected due to having a domain present in the spamhaus',
            'rejected due to listing in spamhaus',
            'blocked - see https://support.proofpoint.com/dnsbl-lookup',
            'not accepting connections',
          ],
          'hasmoved' => [
            # - 550 5.1.6 recipient no longer on server: *****@icloud.com
            'recipient no longer on server',
          ],
          'mailboxfull' => [
            # - 552 5.2.2 <****@icloud.com>: user is over quota (in reply to RCPT TO command)
            'user is over quota',
          ],
          'norelaying' => [
            # - 554 5.7.1 <*****@icloud.com>: Relay access denied
            'relay access denied',
          ],
          'notaccept' => ['host/domain does not accept mail'],
          'policyviolation' => [
            # - 550 5.7.1 [CS01] Message rejected due to local policy.
            #   Please visit https://support.apple.com/en-us/HT204137
            'due to local policy',
          ],
          'rejected' => [
            # - 450 4.1.8 <kijitora@example.jp>: Sender address rejected: Domain not found
            'sender address rejected',
          ],
          'speeding' => [
            # - 421 4.7.1 Messages to ****@icloud.com deferred due to excessive volume.
            #   Try again later - https://support.apple.com/en-us/HT204137
            'due to excessive volume',
          ],
          'userunknown' => [
              # - 550 5.1.1 <****@icloud.com>: inactive email address (in reply to RCPT TO command)
              # - 550 5.1.1 unknown or illegal alias: ****@icloud.com
              'inactive email address',
              'user does not exist',
              'unknown or illegal alias',
          ],
        }.freeze

        # Detect bounce reason from Apple iCloud Mail
        # @param    [Sisimai::Fact] argvs   Parsed email object
        # @return   [String]                The bounce reason for Apple
        # @see      https://support.apple.com/en-us/102322
        #           https://www.postmastery.com/icloud-postmastery-page/
        #           https://smtpfieldmanual.com/provider/apple
        # @since v5.0.4
        def get(argvs)
          issuedcode = argvs['diagnosticcode'].downcase
          reasontext = ''

          MessagesOf.each_key do |e|
            MessagesOf[e].each do |f|
              next unless issuedcode.include?(f)
              reasontext = e
              break
            end
            break if reasontext.size > 0
          end

          return reasontext
        end

      end
    end
  end
end

