module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Data
    # object as an argument of get() method when the value of "rhost" of the object
    # is "aspmx.l.google.com". This class is called only Sisimai::Data class.
    module GoogleApps
      class << self
        # Imported from p5-Sisimail/lib/Sisimai/Rhost/GoogleApps.pm
        SMTPErrorSet = {
          'X.1.1' => [
            {
              'reason' => 'userunknown',
              'regexp' => [ %r/The email account that you tried to reach does not exist[.]/ ],
            }
          ],
          'X.1.2' => [
            {
              'reason' => 'hostunknown',
              'regexp' => [ %r/We weren't able to find the recipient domain[.]/ ],
            },
          ],
          'X.2.1' => [
            {
              'reason' => 'undefined',
              'regexp' => [
                %r/The user you are trying to contact is receiving mail too quickly[.]/,
                %r/The user you are trying to contact is receiving mail at a rate/,
              ],
            },
            {
              'reason' => 'suspend',
              'regexp' => [ %r/The email account that you tried to reach is disabled[.]/ ],
            },
          ],
          'X.2.2' => [
            {
              'reason' => 'mailboxfull',
              'regexp' => [ %r/The email account that you tried to reach is over quota[.]/ ],
            },
          ],
          'X.2.3' => [
            {
              'reason' => 'exceedlimit',
              'regexp' => [ %r/Your message exceeded Google's message size limits[.]/ ],
            },
          ],
          'X.3.0' => [
            {
              'reason' => 'undefined',
              'regexp' => [
                %r/Mail server temporarily rejected message[.]/,
                %r/Multiple destination domains per transaction is unsupported[.]/,
              ],
            },
          ],
          'X.4.2' => [
            {
              'reason' => 'expired',
              'regexp' => [ %r/Timeout [-] closing connection[.]/ ],
            },
          ],
          'X.4.5' => [
            {
              'reason' => 'undefined',
              'regexp' => [ %r/Server busy, try again later[.]/ ],
            },
            {
              'reason' => 'exceedlimit',
              'regexp' => [ %r/Daily sending quota exceeded[.]/ ],
            },
          ],
          'X.5.0' => [
            {
              'reason' => 'undefined',
              'regexp' => [ 
                %r/SMTP protocol violation, see RFC 2821[.]/,
                %r/SMTP protocol violation, no commands allowed to pipeline after STARTTLS/,
              ],
            },
          ],
          'X.5.1' => [
            {
              'reason' => 'syntaxerror',
              'regexp' => [
                %r/STARTTLS may not be repeated[.]/,
                %r/Too many unrecognized commands, goodbye[.]/,
                %r/Unimplemented command[.]/,
                %r/Unrecognized command[.]/,
                %r|EHLO/HELO first[.]|,
                %r/MAIL first[.]/,
                %r/RCPT first[.]/,
              ],
            },
            {
              'reason' => 'securityerror',
              'regexp' => [ %r/Authentication Required[.]/ ],
            },
          ],
          'X.5.2' => [
            {
              'reason' => 'undefined',
              'regexp' => [ %r/Cannot Decode response[.]/ ],
            },
            {
              'reason' => 'syntaxerror',
              'regexp' => [ %r/Syntax error[.]/ ],
            },
          ],
          'X.5.3' => [
            {
              'reason' => 'undefined',
              'regexp' => [
                %r/Domain policy size per transaction exceeded[,]/,
                %r/Your message has too many recipients[.]/,
              ],
            },
          ],
          'X.5.4' => [
            {
              'reason' => 'syntaxerror',
              'regexp' => [ %r/Optional Argument not permitted for that AUTH mode[.]/ ],
            },
          ],
          'X.6.0' => [
            {
              'reason' => 'contenterror',
              'regexp' => [
                %r/Mail message is malformed[.]/,
                %r/Message exceeded 50 hops/,
              ],
            },
          ],
          'X.7.0' => [
            {
              'reason' => 'blocked',
              'regexp' => [
                %r/IP not in whitelist for RCPT domain, closing connection[.]/,
                %r/Our system has detected an unusual rate of unsolicited mail originating from your IP address[.]/,
              ],
            },
            {
              'reason' => 'expired',
              'regexp' => [
                %r/Temporary System Problem. Try again later[.]/,
                %r/Try again later, closing connection[.]/,
              ],
            },
            {
              'reason' => 'securityerror',
              'regexp' => [
                %r/TLS required for RCPT domain, closing connection[.]/,
                %r/No identity changes permitted[.]/,
                %r/Must issue a STARTTLS command first[.]/,
                %r/Too Many Unauthenticated commands[.]/,
              ],
            },
            {
              'reason' => 'systemerror',
              'regexp' => [ %r/Cannot authenticate due to temporary system problem[.]/ ],
            },
            {
              'reason' => 'norelaying',
              'regexp' => [ %r/Mail relay denied[.]/ ],
            },
            {
              'reason' => 'rejected',
              'regexp' => [ %r/Mail Sending denied[.]/ ],
            },
          ],
          'X.7.1' => [
            {
              'reason' => 'securityerror',
              'regexp' => [
                %r/Application-specific password required[.]/,
                %r/Please log in with your web browser and then try again[.]/,
                %r/Username and Password not accepted[.]/,
              ],
            },
            {
              'reason' => 'mailboxfull',
              'regexp' => [ %r/Email quota exceeded[.]/ ],
            },
            {
              'reason' => 'blocked',
              'regexp' => [
                %r/Our system has detected an unusual rate of unsolicited mail originating from your IP address[.]/,
                %r/The IP you[']re using to send mail is not authorized to send email directly to our servers[.]/,
              ],
            },
            {
              'reason' => 'contenterror',
              'regexp' => [ %r/Our system has detected that this message is likely unsolicited mail[.]/ ],
            },
            {
              'reason' => 'filtered',
              'regexp' => [ %r/The user or domain that you are sending to [(]or from[)] has a policy/ ],
            },
            {
              'reason' => 'rejected',
              'regexp' => [ %r/Unauthenticated email is not accepted from this domain[.]/ ],
            },
          ],
          'X.7.4' => [
            {
              'reason' => 'securityerror',
              'regexp' => [ %r/Unrecognized Authentication Type[.]/ ],
            },
          ],
        }

        # Detect bounce reason from Google Apps
        # @param    [Sisimai::Data] argvs   Parsed email object
        # @return   [String]                The bounce reason for Google Apps
        # @see      https://support.google.com/a/answer/3726730?hl=en
        def get(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return argvs.reason if argvs.reason.size > 0

          statuscode = argvs.deliverystatus.sub(/\A\d[.](\d+[.]\d+)\z/, 'X.\1')
          statusmesg = argvs.diagnosticcode
          reasontext = ''
          errortable = SMTPErrorSet[statuscode] || []

          errortable.each do |e|
            # Try to match
            next unless e['regexp'].find { |a| statusmesg =~ a }
            reasontext = e['reason']
            break if reasontext.size > 0
          end
          return reasontext
        end

      end
    end
  end
end
