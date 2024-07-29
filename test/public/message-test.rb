require 'minitest/autorun'
require 'sisimai/message'

class MessageTest < Minitest::Test
  Methods = { class:  %w[rise sift part tidy makemap] }
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
  RFC1894 = {
    'ac-0' => { 'a' => 'Action: failed', 'b' => ['Action: FAILED', 'ACTION:   Failed'] },
    'ad-0' => { 'a' => 'Arrival-Date: Sat, 3 Oct 2020 20:11:48 +0900', 'b' => ['Arrival-DATE: Sat,      3 Oct 2020 20:11:48 +0900']},
    'dc-0' => { 'a' => 'Diagnostic-Code: smtp; 550 Host does not accept mail', 'b' => ['Diagnostic-code:SMTP;550 Host does not accept mail']},
    'fr-0' => { 'a' => 'Final-Recipient: rfc822; neko@libsisimai.org', 'b' => ['Final-recipient: RFC822;NEKO@libsisimai.org']},
    'la-0' => { 'a' => 'Last-Attempt-Date: Sat, 3 Oct 2020 20:12:06 +0900', 'b' => ['Last-Attempt-DATE:Sat, 3    Oct 2020 20:12:06 +0900']},
    'or-0' => { 'a' => 'Original-Recipient: rfc822; neko@example.com', 'b' => ['Original-recipient:rfc822;NEKO@example.com']},
    'fm-0' => { 'a' => 'Received-From-MTA: dns; localhost', 'b' => ['Received-From-mta:    DNS; LocalHost']},
    'rm-0' => { 'a' => 'Remote-MTA: dns; mx.libsisimai.org', 'b' => ['Remote-mta: DNS; mx.libsisimai.org']},
    'rm-1' => { 'a' => 'Reporting-MTA: dns; nyaan.example.jp', 'b' => ['Reporting-mta: DNS;   nyaan.example.jp']},
    'st-0' => { 'a' => 'Status: 5.0.0 (permanent failure)', 'b' => ['STATUS:    5.0.0 (permanent failure)']},
    'xa-0' => { 'a' => 'X-Actual-Recipient: rfc822; neko@libsisimai.org', 'b' => ['X-Actual-rEcipient:rfc822;NEKO@libsisimai.org']},
    'xo-0' => { 'a' => 'X-Original-Message-ID: <NEKOCHAN>', 'b' => ['x-original-message-ID:     <NEKOCHAN>']},
    'ct-0' => { 'a' => 'Content-Type: text/plain', 'b' => ['content-type:     TEXT/plain'] },
    'ct-1' => {
      'a' => 'Content-Type: message/delivery-status; charset=us-ascii; boundary="Neko-Nyaan-22=="',
      'b' => [
        'Content-Type:   message/xdelivery-status; charset=us-ascii; boundary="Neko-Nyaan-22=="',
        'Content-Type: message/xdelivery-status;   charset=us-ascii; boundary="Neko-Nyaan-22=="',
        'Content-Type: message/xdelivery-status; charset=us-ascii;   boundary="Neko-Nyaan-22=="',
        'content-type: message/xdelivery-status; CharSet=us-ascii; Boundary="Neko-Nyaan-22=="',
        'content-Type: Message/Xdelivery-Status; CharSet=us-ascii; Boundary="Neko-Nyaan-22=="',
        'Content-type:message/xdelivery-status;CharSet=us-ascii;Boundary="Neko-Nyaan-22=="',
      ],
    },
  }

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

    ca = { data: Mailtxt, hook: Lambda1 }
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

  def test_tidy
    cv = Sisimai::Message.tidy(RFC822B)
    assert_instance_of ::String, cv
    assert_equal true, cv.size > 0
    assert_match %r|Content-Type: text/plain|, cv
    refute_match %r|content-type:   |, cv

  RFC1894.each_key do |e|
    f = RFC1894[e]

    f['b'].each do |p|
      v = Sisimai::Message.tidy(p)
      v = v.chomp("")
      assert_equal f['a'], v
    end
  end




  end
end

