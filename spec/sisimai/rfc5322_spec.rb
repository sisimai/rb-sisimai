require 'spec_helper'
require 'sisimai/rfc5322'

describe Sisimai::RFC5322 do
  cn = Sisimai::RFC5322
  describe '.HEADERFIELDS' do
    context '()' do
      v = cn.HEADERFIELDS()
      it 'returns Hash' do
        expect(v).to be_a_kind_of(Hash)
        v.each_key do |e|
          expect(e).to match(/\A[a-z-]+\z/)
          expect(v[e]).to be true
        end
      end
    end

    context '("date")' do
      v = cn.HEADERFIELDS(:date)
      it 'returns Array' do
        expect(v).to be_a_kind_of(Array)
        v.each do |e|
          expect(e).to match(/\A[A-Za-z-]+\z/)
          expect(e).to be_a_kind_of(String)
        end
      end
    end

    context '("neko")' do
      v = cn.HEADERFIELDS(:neko)
      it 'returns Hash' do
        expect(v).to be_a_kind_of(Hash)
        v.each_key do |e|
          expect(e).to match(/\A[a-z-]+\z/)
          expect(v[e]).to be_a_kind_of(Array)
          v[e].each do |f|
            expect(f).to match(/\A[A-Za-z-]+\z/)
          end
        end
      end
    end

  end

  describe '.LONGFIELDS' do
    v = cn.LONGFIELDS
    it 'returns Hash' do
      expect(v).to be_kind_of(Hash)
      v.each_key do |e|
        expect(e).to match(/\A[a-z-]+\z/)
        expect(v[e]).to be_a_kind_of(TrueClass)
        expect(v[e]).to be_truthy
      end
    end
  end

  postmaster = [
    'mailer-daemon@example.jp',
    'MAILER-DAEMON@example.cat',
    'Mailer-Daemon <postmaster@example.org>',
    'MAILER-DAEMON',
    'postmaster',
    'postmaster@example.org',
  ]
  emailaddrs = [
    'neko@example.jp',
    'neko+nyaa@example.jp',
    'nyaa+neko=example.jp@example.org',
    '"neko@nyaan"@example.org',
    '"neko nyaan"@exaple.org',
    '{nekonyaan}@example.org',
    'neko|nyaan@example.org',
    'neko?nyaan@example.org',
    '"neko<>nyaan"@example.org',
    '"neko(nyaan)"@example.org',
    '"nora(:;)neko"@example.org',
    'neko^_^nyaan@example.org',
    'neko$nyaan@example.org',
    'neko%nyaan@example.org',
    'neko&nyaan@example.org',
    'neko?nyaan@example.org',
    'neko|nyaan@example.org',
    '"neko\\nyaan"@example.org',
  ]

  describe '.is_emailaddress' do
    describe 'Valid Email Address String' do
      emailaddrs.each do |e|
        context "(#{e})" do
          it('returns true') { expect(cn.is_emailaddress(e)).to be true }
        end
      end
    end

    describe 'Invalid Email Address String' do
      isnotaddrs = ['neko', 'neko%example.jp', nil]
      isnotaddrs.each do |e|
        context "(#{e})" do
          it('returns false') { expect(cn.is_emailaddress(e)).to be false }
        end
      end
    end
  end

  describe '.is_mailerdaemon' do
    describe 'Valid MAILER-DAEMON Address String' do
      postmaster.each do |e|
        context "(#{e})" do
          it('returns true') { expect(cn.is_mailerdaemon(e)).to be true }
        end
      end
    end
    describe 'Invalid MAILER-DAEMON Address String' do
      emailaddrs.each do |e|
        context "(#{e})" do
          it('returns false') { expect(cn.is_mailerdaemon(e)).to be false }
        end
      end
    end
  end

  describe '.received' do
    received00 = [
      'from mx.example.org (c182128.example.net [192.0.2.128]) by mx.example.jp (8.14.4/8.14.4) with ESMTP id oBB3JxRJ022484 for <shironeko@example.jp>; Sat, 11 Dec 2010 12:20:00 +0900 (JST)',
      'from localhost (localhost [127.0.0.1]) (ftp://ftp.isi.edu/in-notes/rfc1894.txt) by marutamachi.example.org with dsn; Sat, 11 Dec 2010 12:19:59 +0900',
      'from [127.0.0.1] (c10920.example.com [192.0.2.20]) by marutamachi.example.org with SMTP; Sat, 11 Dec 2010 12:19:17 +0900 id 0EFECD4E.4D02EDD9.0000C5BA',
      'from host (HELO exchange.example.co.jp) (192.0.2.57) by 0 with SMTP; 29 Apr 2007 23:19:00 -0000',
      'from mail by marutamachi.example.org with local (Exim 4.72) id 1X58pT-0004bZ-Co for shironeko@example.jp; Thu, 10 Jul 2014 16:31:43 +0900',
      'from mail4.example.co.jp (1234c.example.com [192.0.2.1]) by mx.example.jp (8.14.4/8.14.4) with ESMTP id r4B0078w00000 for <postmaster@example.jp>; Mon, 11 #May 2013 00:00:00 +0900 (JST)',
      '(from webmaster@localhost) by mail4.example.co.jp (8.14.4/8.14.4/Submit) id r4B003v000000 for shironeko@example.ne.jp; Mon, 11 May 2013 00:00:00 +0900',
      'from biglobe.ne.jp by rcpt-expgw4.biglobe.ne.jp (0000/0000000000) with SMTP id p0000000000000 for <kijitora@mx.example.com>; Thu, 11 Feb 2014 00:00:00 +090#0',
      'from wfilter115 (wfilter115-a0 [172.26.26.68]) by wsmtpr24.ezweb.ne.jp (EZweb Mail) with ESMTP id EF283A071 for <user@example.or.jp>; Sun,  7 Sep 2008 21:4#0:12 +0900 (JST)',
      'from vagrant-centos65.example.com (c213502.kyoto.example.ne.jp [192.0.2.135]) by aneyakoji.example.jp (V8/cf) with ESMTP id s6HB0VsJ028505 for <kijitora@ex#ample.jp>; Thu, 17 Jul 2014 20:00:32 +0900',
      'from localhost (localhost [local]); by localhost (OpenSMTPD) with ESMTPA id 1e2a9eaa; for <kijitora@example.jp>;',
      'from [127.0.0.1] (unknown [172.25.191.1]) by smtp.example.com (Postfix) with ESMTP id 7874F1FB8E; Sat, 21 Jun 2014 18:34:34 +0000 (UTC)',
      'from unknown (HELO ?127.0.0.1?) (172.25.73.1) by 172.25.73.144 with SMTP; 1 Jul 2014 08:30:40 -0000',
      'from [192.0.2.25] (p0000-ipbfpfx00kyoto.kyoto.example.co.jp [192.0.2.25]) (authenticated bits=0) by smtpgw.example.jp (V8/cf) with ESMTP id r9G5FXh9018568',
      'from localhost (localhost) by nijo.example.jp (V8/cf) id s1QB5ma0018057; Wed, 26 Feb 2014 06:05:48 -0500',
      'by 10.194.5.104 with SMTP id r8csp190892wjr; Fri, 18 Jul 2014 00:31:04 -0700 (PDT)',
      'from gargamel.example.com (192.0.2.146) by athena.internal.example.com with SMTP; 12 Jun 2013 02:22:14 -0000',
    ]

    describe 'Valid Received Header String' do
      received00.each do |e|
        context "(#{e})" do
          it('returns Array') { expect(cn.received(e)).to be_a_kind_of(Array) }
          it('have elements') { expect(cn.received(e).size).to be > 0 }
          cn.received(e).each do |f|
            example "#{f} is a valid hostname or IP address" do
              expect(f.size).to be > 0
              expect(f).to match(/\A[-.0-9A-Za-z]+\z/)
            end
          end
        end
      end
    end
  end

  describe '.fillet' do
    rfc822body = <<'EOB';
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
Content-Type: text/plain
MIME-Version: 1.0
From: Shironeko <shironeko@example.co.jp>
To: Kijitora <shironeko@example.co.jp>
Subject: Nyaaaan

Nyaaan

__END_OF_EMAIL_MESSAGE__
EOB
    context 'Valid email body string' do
      emailsteak = Sisimai::RFC5322.fillet(rfc822body, %r|^Content-Type:[ ]message/rfc822|)
      it('returns Array')   { expect(emailsteak).to be_a_kind_of(Array) }
      it('has 2 elements')  { expect(emailsteak.size).to be == 2 }

      it('contains string') { expect(emailsteak[0]).to be_a_kind_of(::String) }
      it('is not empty')    { expect(emailsteak[0]).not_to be_empty }
      it('includes "Final-Recipient:"') { expect(emailsteak[0]).to match(/^Final-Recipient:/) }
      it('does not include "Return-Path:"') { expect(emailsteak[0]).not_to match(/^Return-Path:/) }
      it('does not include "binary"')       { expect(emailsteak[0]).not_to match(/binary$/) }

      it('contains string') { expect(emailsteak[1]).to be_a_kind_of(::String) }
      it('is not empty')    { expect(emailsteak[1]).not_to be_empty }
      it('includes "Subject:"')    { expect(emailsteak[1]).to match(/^Subject:/) }
      it('does not include "Remote-MTA:"') { expect(emailsteak[1]).not_to match(/^Remote-MTA:/) }
      it('does not include "Neko-Nyaan"')  { expect(emailsteak[1]).not_to match(/^Neko-Nyaan/) }
    end
  end

end

