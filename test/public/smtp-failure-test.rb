require 'minitest/autorun'
require 'sisimai/smtp/failure'

class SMTPFailure < Minitest::Test
  Methods = { class: %w[is_permanent is_temporary is_hardbounce is_softbounce] }
  Bounces = {
    soft: [
      'blocked', 'contenterror', 'exceedlimit', 'expired', 'filtered', 'mailboxfull', 'mailererror',
      'mesgtoobig', 'networkerror', 'norelaying', 'rejected', 'securityerror', 'spamdetected',
      'suspend', 'systemerror', 'systemfull', 'toomanyconn', 'undefined', 'onhold',
    ],
    hard: ['userunknown', 'hostunknown', 'hasmoved', 'notaccept'],
  }
  NoError = ['delivered', 'feedback', 'vacation']
  WasSent = ['smtp; 2.1.5 250 OK']
  TempErr = [
    'smtp; 450 4.0.0 Temporary failure',
    'smtp; 555 4.4.7 Message expired: unable to deliver in 840 minutes.<421 4.4.2 Connection timed out>',
    'SMTP; 450 4.7.1 Access denied. IP name lookup failed [192.0.2.222]',
    'smtp; 451 4.7.650 The mail server [192.0.2.25] has been',
    '4.4.1 (Persistent transient failure - routing/network: no answer from host)',
  ]
  PermErr = [
    'smtp;550 5.2.2 <mikeneko@example.co.jp>... Mailbox Full',
    'smtp; 550 5.1.1 Mailbox does not exist',
    'smtp; 550 5.1.1 Mailbox does not exist',
    'smtp; 552 5.2.2 Mailbox full',
    'smtp; 552 5.3.4 Message too large',
    'smtp; 500 5.6.1 Message content rejected',
    'smtp; 550 5.2.0 Message Filtered',
    '550 5.1.1 <kijitora@example.jp>... User Unknown',
    'SMTP; 552-5.7.0 This message was blocked because its content presents a potential',
    'SMTP; 550 5.1.1 Requested action not taken: mailbox unavailable',
    'SMTP; 550 5.7.1 IP address blacklisted by recipient',
  ]

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::SMTP::Failure, e }
  end

  def test_is_permanent
    WasSent.each { |e| assert_equal false, Sisimai::SMTP::Failure.is_permanent(e) }
    TempErr.each { |e| assert_equal false, Sisimai::SMTP::Failure.is_permanent(e) }
    PermErr.each { |e| assert_equal true,  Sisimai::SMTP::Failure.is_permanent(e) }

    ce = assert_raises ArgumentError do
      Sisimai::SMTP::Failure.is_permanent()
      Sisimai::SMTP::Failure.is_permanent(nil, nil)
    end
  end

  def test_is_temporary
    WasSent.each { |e| assert_equal false, Sisimai::SMTP::Failure.is_temporary(e) }
    TempErr.each { |e| assert_equal true,  Sisimai::SMTP::Failure.is_temporary(e) }
    PermErr.each { |e| assert_equal false, Sisimai::SMTP::Failure.is_temporary(e) }

    ce = assert_raises ArgumentError do
      Sisimai::SMTP::Failure.is_temporary()
      Sisimai::SMTP::Failure.is_temporary(nil, nil)
    end
  end

  def test_is_hardbounce
    Bounces[:soft].each { |e| assert_equal false, Sisimai::SMTP::Failure.is_hardbounce(e) }
    Bounces[:hard].each do |e|
      assert_equal true,  Sisimai::SMTP::Failure.is_hardbounce(e)
      assert_equal true,  Sisimai::SMTP::Failure.is_hardbounce(e, '503 Not accept any email') if e == 'notaccept'
      assert_equal false, Sisimai::SMTP::Failure.is_hardbounce(e, '458 Not accept any email') if e == 'notaccept'
    end

    ce = assert_raises ArgumentError do
      Sisimai::SMTP::Failure.is_hardbounce()
      Sisimai::SMTP::Failure.is_hardbounce(nil, nil, nil)
    end
  end

  def test_is_softbounce
    Bounces[:soft].each { |e| assert_equal true, Sisimai::SMTP::Failure.is_softbounce(e) }
    Bounces[:hard].each do |e|
      assert_equal false, Sisimai::SMTP::Failure.is_softbounce(e)
      assert_equal false, Sisimai::SMTP::Failure.is_softbounce(e, '503 Not accept any email') if e == 'notaccept'
      assert_equal true,  Sisimai::SMTP::Failure.is_softbounce(e, '458 Not accept any email') if e == 'notaccept'
    end

    ce = assert_raises ArgumentError do
      Sisimai::SMTP::Failure.is_softbounce()
      Sisimai::SMTP::Failure.is_softbounce(nil, nil, nil)
    end
  end

end

