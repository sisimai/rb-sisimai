require 'minitest/autorun'
require 'sisimai/reason'
require 'sisimai'

class ReasonChildrenTest < Minitest::Test
  Reasons = {
    'AuthFailure'     => [
      "550 5.1.0 192.0.2.222 is not allowed to send from <example.net> per it's SPF Record",
      "Unauthenticated email from libsisimai.org is not accepted due to domain's DMARC policy",
      'Message rejected due to DMARC. Please see https://postmaster.comcast.net/smtp-error-codes.php#DM000001',
      '552 5.2.0 nyaan DMARC Policy Enforcement: https://postmaster.comcast.net/smtp-error-codes.php#ODM00001',
    ],
    'BadReputation'   => [
      '451 4.7.650 The mail server [192.0.2.2] has been temporarily rate limited due to IP reputation.',
      '550 Connections from mx.example.jp (192.0.2.2) are being rejected due to a poor email reputation score.',
      '421 4.7.0 [TSS04] Messages from 192.0.2.25 temporarily deferred due to unexpected volume or user complaints',
    ],
    'Blocked'         => [
      '550 Access from ip address 192.0.2.1 blocked.',
      'Remote host said: 554 INVALID IP FOR SENDING MAIL OF DOMAIN amazonses.com [RCPT_TO]',
      '551 Server access forbidden by your IP 192.0.2.2 websites spamcop.net, mailspike.net for removal',
      'client [192.0.2.1] blocked using dnsbl.sorbs.net Please see http://support.mailhostbox.com/',
      '554 mx.example.jp 192.0.2.25 found on one or more DNSBLs, see https://postmaster.comcast.net/smtp-error-codes.php#BL000001',
    ],
    'ContentError'    => ['550 5.6.0 the headers in this message contain improperly-formatted binary content'],
    'EmailTooLarge'   => [
      '400 4.2.3 Message too big',
      '#550 5.2.3 RESOLVER.RST.RecipSizeLimit; message too large for this recipient ##',
      '552 5.2.3 Message size exceeds fixed maximum message size (10485760)',
      '5.2.3 Message too large',
      'permanent failure 5.3.0 - Other mail system problem #5.3.4 message header size exceeds limit',
    ],
    'Expired'         => [
      '421 4.4.7 Delivery time expired',
      'Delivery to the following recipient has been delayed: Message will be retried for 2 more day(s)',
    ],
    'FailedSTARTTLS'  => ['538 5.7.10 STARTTLS is required to send mail'],
    'Filtered'        => [
      '550 5.1.2 User reject',
      'You have been blocked by the recipient',
    ],
    'HasMoved'        => ['550 5.1.6 address neko@cat.cat has been replaced by neko@example.jp'],
    'HostUnknown'     => [
      '550 5.2.1 Host Unknown',
      'kijitora@neko.example.jp: Domain does not exist',
      '554 The mail could not be delivered to the recipient because the domain is not reachable.',
      '550 5.1.7 No such domain neko.example.com',
    ],
    'MailboxFull'     => [
      '450 4.2.2 Mailbox full',
      '452 Insufficient disk space; try again later',
      '5.2.2 <pseudo-local-part-of-apple-icloud-mail@icloud.com>: user is over quota (in reply to RCPT TO)',
      '550 5.2.2 <kijitora@example.co.jp>... Mailbox Full',
      'save to /mail/spool/q002.kijitora.gol.com/gol.com/22r/cat/n2.nyaan mailbox is full: retry timeout exceeded',
    ],
    'MailerError'     => [
      'X-Unix; 255',
      %q(554 "|IFS=' ' && exec /usr/local/bin/procmail -f- || exit 75 #kijitora"... Service unavailable),
      'pipe to |/usr/local/neko/bin/cat kijitora@example.com /home/neko/.cat',
    ],
    'NetworkError'    => [
      '554 5.4.6 Too many hops',
      '554 5.4.6 Hop count exceeded - possible mail loop',
      'neko.example.com[192.0.2.2]:25: No route to host',
      'Error transferring to neko22.example.org; Maximum hop count exceeded. Message probably in a routing loop.',
    ],
    'NoRelaying'      => [
      '550 5.0.0 Relaying Denied',
      '550 relay not permitted',
      '550 5.7.1 Unable to relay for neko@example.com',
    ],
    'NotAccept'       => [
      '556 this server does not accept mail',
      '550 5.1.2 <nekochan@libsisimai.org>... Host unknown (Name server: .: host not found)',
    ],
    'NotCompliantRFC' => [
      '550 5.7.1 This message is not RFC 5322 compliant. There are multiple Subject headers.',
      'There are multiple Subject headers. Please visit https://support.google.com/mail/?p=RfcMessageNonCompliant',
      "554 Transaction failed: Duplicate header 'DKIM-Signature'. (in reply to end of DATA command)",
    ],
    'OnHold'          => ['5.9.301 error'],
    'Rejected'        => [
      '550 5.1.8 Domain of sender address example.org does not exist',
      '5.7.1 Access denied (in reply to MAIL FROM command)',
      'Invalid sender domain',
    ],
    'RequirePTR'      => [
      '550 5.7.25 [192.0.2.25] The IP address sending this message does not have a PTR record setup',
      '571 No PTR Record found. Reverse DNS required:',
      '550 5.7.1 Connections not accepted from servers without a valid sender domain. Fix reverse DNS for 203.0.113.2',
      'Reverse DNS failure : Try again later',
      'PTR lookup failure',
    ],
    'PolicyViolation' => [
      '570 5.7.7 Email not accepted for policy reasons',
      '550 Denied by policy',
      '554 email rejected due to security policies - MCSpamSignature.sa.2.2 (in reply to end of DATA command)',
    ],
    'SecurityError'   => [
      '570 5.7.0 Authentication failure',
      '#550 5.7.1 RESOLVER.RST.AuthRequired; authentication required ##rfc822;neko-nyaan@cat.example.jp',
    ],
    'SpamDetected'    => [
      '570 5.7.7 Spam Detected',
      '554 5.7.1 Mail Score (59) over MessageScoringUpperLimit (50) - send error reports to postmaster@example.net',
    ],
#   'Suppressed'      => ['There is no sample email which is returned due to being listed in the suppression list'],
    'Suspend'         => [
      '550 5.0.0 Recipient suspend the service',
      '550 The domain meangel.net is currently suspended. Try later.',
      '550 5.7.1 <kijitora@example.com>: Recipient address rejected: User kijitora@example.com temporary locked. Please try again later!',
    ],
    'SystemError'     => [
      "500 5.3.5 System config error",
      "554 5.3.5 Local configuration error",
      "X-Postfix; mail for example.jp loops back to myself",
    ],
    'SystemFull'      => ['550 5.0.0 Mail system full'],
    'RateLimited'     => [
      "421 Too many connections",
      "451 4.7.1 <smtp.example.jp[192.0.2.3]>: Client host rejected: Please try again slower",
      "452 4.3.2 Connection rate limit exceeded. (in reply to MAIL FROM command)",
      "421 4.1.0 192.0.2.1 Throttled - try again later. Please see https://postmaster.comcast.net/smtp-error-codes.php#RL000003",
      "451 4.2.0 Throttled - https://postmaster.comcast.net/smtp-error-codes.php#RL000010",
      "Too many sessions opened",
      "Too many emails sent on this session",
      "Too many recipients for message",
      "Your message could not be delivered due to too many invalid recipients",
    ],
    'UserUnknown'     => [
      '550 5.1.1 Unknown User',
      '550 kijitora@example.com... No such user',
      %q|5.1.0 - Unknown address error 550-'No Such User Here"' (delivery attempts: 0)|,
      ': 550 5.1.1 <kijitora@example.jp>: Recipient address rejected: User unknown in local recipient table',
      %q|554 delivery error: dd This user doesn't have a yahoo.com account (this-local-part-does-not-exist@yahoo.com)|,
      %q|procmail: Couldn't create \"/var/spool/mail/neko\" id: r.example.org: No such user|,
      'SMTP;550 5.1.1 <example@comcast.net> recipient mailbox unallocated',
    ],
    'VirusDetected'   => ['550 5.7.9 The message was rejected because it contains prohibited virus or spam content'],
  }

  def test_reason
    cv = Sisimai.rise('./set-of-emails/maildir/bsd/lhost-sendmail-01.eml').shift
    cw = cv.damn
    assert_instance_of Sisimai::Fact, cv
    assert_instance_of Hash, cw

    Reasons.each_key do |e|
      cr = "Sisimai::Reason::#{e}"
      require cr.downcase.gsub('::', '/')
      cx = Module.const_get(cr)

      assert_equal Module, cx.class
      assert_equal e, cx.text;
      refute_empty cx.description
      assert_includes [true, false, nil], cx.true(cw)

      unless e.match(/\A(?:Content|Expire|Mailer|Network|Policy|Security|System|User|NoRelay|OnHold)/)
        # Skip a class its true() method always return undef
        cw['reason'] = e
        assert_equal true, cx.true(cw)

        cw['reason'] = 'Undefined'
        cw['diagnosticcode'] = Reasons[e][0]
        cw['command'] = if e == 'Rejected' then 'MAIL' else cv.command end
        assert_equal true, cx.true(cw)
      end

      next if e == 'OnHold'
      Reasons[e].each do |ee|
        assert_equal true, cx.match(ee.downcase)
      end
      assert_equal false, cx.match(nil)

      ce = assert_raises ArgumentError do
        cx.text(nil)
        cx.true()
        cx.match()
        cx.description(nil)
      end
    end

    %w[Delivered Feedback Undefined Vacation SyntaxError].each do |e|
      cr = "Sisimai::Reason::#{e}"
      require cr.downcase.gsub('::', '/')
      cx = Module.const_get(cr)

      assert_equal Module, cx.class
      assert_equal e, cx.text;
      refute_empty cx.description
      assert_includes [false, nil], cx.true(cw)
    end


  end

end

