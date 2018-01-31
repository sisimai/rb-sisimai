module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
    # object as an argument of get() method when the value of "rhost" of the object
    # is "aspmx.l.google.com". This class is called only Sisimai::Data class.
    module GoogleApps
      class << self
        # Imported from p5-Sisimail/lib/Sisimai/Rhost/GoogleApps.pm
        StatusList = {
          # https://support.google.com/a/answer/3726730
          'X.1.1' => [{ reason: 'userunknown', stirng: ['The email account that you tried to reach does not exist.'] }],
          'X.1.2' => [{ reason: 'hostunknown', stirng: ["We weren't able to find the recipient domain."] }],
          'X.2.1' => [
            { reason: 'suspend',   stirng: ['The email account that you tried to reach is disabled.'] },
            { reason: 'undefined', stirng: ['The user you are trying to contact is receiving mail ']  },
          ],
          'X.2.2' => [{ reason: 'mailboxfull', stirng: ['The email account that you tried to reach is over quota.'] }],
          'X.2.3' => [{ reason: 'exceedlimit', stirng: ["Your message exceeded Google's message size limits."] }],
          'X.3.0' => [
            { reason: 'syntaxerror', stirng: ['Multiple destination domains per transaction is unsupported.'] },
            { reason: 'undefined',   stirng: ['Mail server temporarily rejected message.'] },
          ],
          'X.4.2' => [{ reason: 'expired', stirng: ['Timeout - closing connection.'] }],
          'X.4.5' => [
            { reason: 'exceedlimit', stirng: ['Daily sending quota exceeded.'] },
            { reason: 'undefined',   stirng: ['Server busy, try again later.'] },
          ],
          'X.5.0' => [{ reason: 'syntaxerror', stirng: ['SMTP protocol violation'] }],
          'X.5.1' => [
            { reason: 'securityerror', stirng: ['Authentication Required.'] },
            {
              reason: 'syntaxerror',
              stirng: [
                'STARTTLS may not be repeated',
                'Too many unrecognized commands, goodbye.',
                'Unimplemented command.',
                'Unrecognized command.',
                'EHLO/HELO first.',
                'MAIL first.',
                'RCPT first.',
              ],
            },
          ],
          'X.5.2' => [
            { reason: 'securityerror', stirng: ['Cannot Decode response.'] },   # 2FA related error, maybe.
            { reason: 'syntaxerror',   stirng: ['Syntax error.'] },
          ],
          'X.5.3' => [
            { reason: 'mailboxfull',    stirng: ['Domain policy size per transaction exceeded,'] },
            { reason: 'policyviolation',stirng: ['Your message has too many recipients.'] },
          ],
          'X.5.4' => [{ reason: 'syntaxerror', stirng: ['Optional Argument not permitted for that AUTH mode.'] }],
          'X.6.0' => [
            { reason: 'contenterror', stirng: ['Mail message is malformed.'] },
            { reason: 'networkerror', stirng: ['Message exceeded 50 hops'] }
          ],
          'X.7.0' => [
            {
              reason: 'blocked',
              stirng: [
                'IP not in whitelist for RCPT domain, closing connection.',
                'Our system has detected an unusual rate of unsolicited mail originating from your IP address.',
              ],
            },
            {
              reason: 'expired',
              stirng: [
                'Temporary System Problem. Try again later.',
                'Try again later, closing connection.',
              ],
            },
            {
              reason: 'securityerror',
              stirng: [
                'TLS required for RCPT domain, closing connection.',
                'No identity changes permitted.',
                'Must issue a STARTTLS command first.',
                'Too Many Unauthenticated commands.',
              ],
            },
            { reason: 'systemerror', stirng: ['Cannot authenticate due to temporary system problem.'] },
            { reason: 'norelaying',  stirng: ['Mail relay denied.'] },
            { reason: 'rejected',    stirng: ['Mail Sending denied.'] },
          ],
          'X.7.1' => [
            { reason: 'mailboxfull', stirng: ['Email quota exceeded.'] },
            {
              reason: 'securityerror',
              stirng: [
                'Application-specific password required.',
                'Please log in with your web browser and then try again.',
                'Username and Password not accepted.',
              ],
            },
            {
              reason: 'blocked',
              stirng: [
                'Our system has detected an unusual rate of unsolicited mail originating from your IP address.',
                "The IP you're using to send mail is not authorized to send email directly to our servers.",
              ],
            },
            { reason: 'spamdetected',   stirng: ['Our system has detected that this message is likely unsolicited mail.'] },
            { reason: 'policyviolation',stirng: ['The user or domain that you are sending to (or from) has a policy'] },
            { reason: 'rejected',       stirng: ['Unauthenticated email is not accepted from this domain.'] },
          ],
          'X.7.4' => [{ reason: 'syntaxerror', stirng: ['Unrecognized Authentication Type.'] }],
        }.freeze

        # Detect bounce reason from Google Apps
        # @param    [Sisimai::Data] argvs   Parsed email object
        # @return   [String]                The bounce reason for Google Apps
        # @see      https://support.google.com/a/answer/3726730?hl=en
        def get(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return argvs.reason if argvs.reason.size > 0

          reasontext = ''
          statuscode = argvs.deliverystatus.clone

          statuscode[0] = 'X'
          return '' unless StatusList[statuscode.to_sym]

          StatusList[statuscode.to_sym].each do |e|
            # Try to match
            next unless e[:regexp].find { |a| argvs.diagnosticcode.include?(a) }
            reasontext = e[:reason]
            break
          end
          return reasontext
        end

      end
    end
  end
end
