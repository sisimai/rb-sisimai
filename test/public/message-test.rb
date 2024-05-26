require 'minitest/autorun'
require 'sisimai/message'

class MessageTest < Minitest::Test
  Methods = { class:  %w[rise load sift part tidy makemap] }
  Mailbox = './set-of-emails/mailbox/mbox-0'
  Fhandle = File.open(Mailbox, 'r')
  Mailtxt = Fhandle.read; Fhandle.close
  Lambda1 = lambda do |argv|
    data = { 'x-mailer' => '', 'return-path' => '' }
    if cv = argv['message'].match(/^X-Mailer:\s*(.+)$/)
      data['x-mailer'] = cv[1]
    end

    if cv = argv['message'].match(/^Return-Path:\s*(.+)$/)
      data['return-path'] = cv[1]
    end
    data['from'] = argv['headers']['from'] || ''
    return data
  end
  RFC822B = '
This is a MIME-encapsulated message
The original message was received at Thu, 9 Apr 2014 23:34:45 +0900
from localhost [127.0.0.1]
   ----- The following addresses had permanent fatal errors -----
<kijitora@example.net>
    (reason: 551 not our customer)
   ----- Transcript of session follows -----
... while talking to mx-0.neko.example.jp.:
<<< 450 busy - please try later
... while talking to mx-1.neko.example.jp.:
>>> DATA
<<< 551 not our customer
550 5.1.1 <kijitora@example.net>... User unknown
<<< 503 need RCPT command [data]
Content-Type: message/delivery-status
Reporting-MTA: dns; mx.example.co.jp
Received-From-MTA: DNS; localhost
Arrival-Date: Thu, 9 Apr 2014 23:34:45 +0900
Final-Recipient: RFC822; kijitora@example.net
Action: failed
Status: 5.1.6
Remote-MTA: DNS; mx-s.neko.example.jp
Diagnostic-Code: SMTP; 551 not our customer
Last-Attempt-Date: Thu, 9 Apr 2014 23:34:45 +0900
Content-Type: message/rfc822
Return-Path: <shironeko@mx.example.co.jp>
Received: from mx.example.co.jp (localhost [127.0.0.1])
	by mx.example.co.jp (8.13.9/8.13.1) with ESMTP id fffff000000001
	for <kijitora@example.net>; Thu, 9 Apr 2014 23:34:45 +0900
Received: (from shironeko@localhost)
	by mx.example.co.jp (8.13.9/8.13.1/Submit) id fff0000000003
	for kijitora@example.net; Thu, 9 Apr 2014 23:34:45 +0900
Date: Thu, 9 Apr 2014 23:34:45 +0900
Message-Id: <0000000011111.fff0000000003@mx.example.co.jp>
content-type:       text/plain
MIME-Version: 1.0
From: Shironeko <shironeko@example.co.jp>
To: Kijitora <shironeko@example.co.jp>
Subject: Nyaaaan
Nyaaan
__END_OF_EMAIL_MESSAGE__
'

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::Message, e }
  end

  def test_rise
    assert_instance_of String, Mailtxt
    refute_empty Mailtxt

    ca = { data: Mailtxt }
    cv = Sisimai::Message.rise(**ca)
    assert_instance_of Hash,   cv
    assert_instance_of Hash,   cv['header']
    assert_instance_of Array,  cv['ds']
    assert_instance_of Hash,   cv['rfc822']
    assert_instance_of String, cv['from']

    ca = {
      data: Mailtxt,
      hook: Lambda1,
      order:[
        'Sisimai::Lhost::Sendmail', 'Sisimai::Lhost::Postfix', 'Sisimai::Lhost::qmail',
        'Sisimai::Lhost::Exchange2003', 'Sisimai::Lhost::Gmail', 'Sisimai::Lhost::Verizon',
      ]
    }
    cv = Sisimai::Message.rise(**ca)
    assert_instance_of Hash,  cv
    assert_instance_of Array, cv['ds']
    assert_instance_of Array, cv['header']['received']
    assert_instance_of Hash,  cv['catch']

    cv['ds'].each do |e|
      assert_equal 'SMTP',    e['spec']
      assert_match /[@]/,     e['recipient']
      assert_equal true,      e.has_key?('command')
      assert_match /\d{4}/,   e['date']
      refute_empty            e['diagnosis']
      refute_empty            e['action']
      assert_match /.+[.].+/, e['rhost']
      assert_match /.+[.].+/, e['lhost']
      assert_equal 'Sendmail',e['agent']
    end

    %w[content-type to subject date from message-id].each { |e| refute_empty cv['header'][e] }
    %w[return-path to subject date from message-id].each  { |e| refute_empty cv['rfc822'][e] }

    refute_empty cv['catch']['x-mailer']
    refute_empty cv['catch']['return-path']
    refute_empty cv['catch']['from']

    ce = assert_raises ArgumentError do
      Sisimai::Message.rise(nil)
      Sisimai::Message.rise(nil, nil)
    end

    ce = assert_raises NoMethodError do
      Sisimai::Message.rise()
    end
  end

  def test_load
    assert_instance_of Array, Sisimai::Message.load('load' => ['Sisimai::Lhost::Postfix'], 'order' => ['Sisimai::Lhost::Postfix'])
    assert_instance_of Array, Sisimai::Message.load('load' => {}, 'order' => [])
    assert_instance_of Array, Sisimai::Message.load('load' => [], 'order' => {})
    ce = assert_raises ArgumentError do
      Sisimai::Message.load()
      Sisimai::Message.load(nil, nil)
    end
  end

  def test_tidy
    cv = Sisimai::Message.tidy(RFC822B)
    assert_instance_of ::String, cv
    assert_equal true, cv.size > 0
    assert_match %r|Content-Type: text/plain|, cv
    refute_match %r|content-type:   |, cv
  end
end

