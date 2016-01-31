[![License](https://img.shields.io/badge/license-BSD%202--Clause-orange.svg)](https://github.com/sisimai/rb-Sisimai/blob/master/LICENSE)
[![Coverage Status](https://img.shields.io/coveralls/sisimai/rb-Sisimai.svg)](https://coveralls.io/r/sisimai/rb-Sisimai)
[![Build Status](https://travis-ci.org/sisimai/rb-Sisimai.svg?branch=master)](https://travis-ci.org/sisimai/rb-Sisimai) 
[![Codacy Badge](https://api.codacy.com/project/badge/grade/38340177e6284a65be69c0c7c3dc2b58)](https://www.codacy.com/app/azumakuniyuki/rb-Sisimai)
[![Ruby](https://img.shields.io/badge/ruby-v2.1.0--v2.2.4-red.svg)](https://www.ruby-lang.org/)

![](http://41.media.tumblr.com/45c8d33bea2f92da707f4bbe66251d6b/tumblr_nuf7bgeyH51uz9e9oo1_1280.png)

Ruby version of Sisimai
=======================

What is Sisimai ? | シシマイ?
=============================
Sisimai is a Ruby library for analyzing RFC5322 bounce emails and generating
structured data from parsed results. Ruby version of Sisimai is ported from
Perl version of Sisimai at https://github.com/sisimai/p5-Sisimai/ .

Sisimai(シシマイ)はRFC5322準拠のエラーメールを解析し、解析結果をデータ構造に
変換するインターフェイスを提供するRubyライブラリです。
https://github.com/sisimai/p5-Sisimai/で公開しているPerl版シシマイから移植しました。

Key Features | 主な特徴的機能
-----------------------------
* __Convert Bounce Mails to Structured Data__ | __エラーメールをデータ構造に変換__
  * Supported formats are Perl and JSON | Perlのデータ形式とJSONに対応
* __Easy to Install, Use.__ | __インストールも使用も簡単__
  * gem install
  * git clone & make


Setting Up Sisimai | シシマイを使う準備
=======================================

System requirements | 動作環境
------------------------------

* [Ruby 2.1.0 or later](https://www.ruby-lang.org/)

Usage | 使い方
==============

Basic usage | 基本的な使い方
----------------------------
make() method provides feature for getting parsed data from bounced email 
messages like following.

```ruby
#! /usr/bin/env ruby
require 'sisimai'
v = Sisimai.make('/path/to/mbox')       # or path to Maildir/

unless v.void
  v.each do |e|
    puts e.class                # Sisimai::Data
    puts e.recipient.class      # Sisimai::Address
    puts e.timestamp.class      # Sisimai::Time

    puts e.addresser.address    # shironeko@example.org # From
    puts e.recipient.address    # kijitora@example.jp   # To
    puts e.recipient.host       # example.jp
    puts e.deliverystatus       # 5.1.1
    puts e.replycode            # 550
    puts e.reason               # userunknown

    h = e.damn                  # Convert to HASH
    j = e.dump('json')          # Convert to JSON string
    puts e.dump('json')         # JSON formatted bounce data
  end
end

# Get JSON string from parsed mailbox or Maildir/
puts Sisimai.dump('/path/to/mbox')  # or path to Maildir/
```

```json
[{"recipient": "kijitora@example.jp", "addresser": "shironeko@1jo.example.org", "feedbacktype": "", "action": "failed", "subject": "Nyaaaaan", "smtpcommand": "DATA", "diagnosticcode": "550 Unknown user kijitora@example.jp", "listid": "", "destination": "example.jp", "smtpagent": "Courier", "lhost": "1jo.example.org", "deliverystatus": "5.0.0", "timestamp": 1291954879, "messageid": "201012100421.oBA4LJFU042012@1jo.example.org", "diagnostictype": "SMTP", "timezoneoffset": "+0900", "reason": "filtered", "token": "ce999a4c869e3f5e4d8a77b2e310b23960fb32ab", "alias": "", "senderdomain": "1jo.example.org", "rhost": "mfsmax.example.jp"}, {"diagnostictype": "SMTP", "timezoneoffset": "+0900", "reason": "userunknown", "timestamp": 1381900535, "messageid": "E1C50F1B-1C83-4820-BC36-AC6FBFBE8568@example.org", "token": "9fe754876e9133aae5d20f0fd8dd7f05b4e9d9f0", "alias": "", "senderdomain": "example.org", "rhost": "mx.bouncehammer.jp", "action": "failed", "addresser": "kijitora@example.org", "recipient": "userunknown@bouncehammer.jp", "feedbacktype": "", "smtpcommand": "DATA", "subject": "バウンスメールのテスト(日本語)", "destination": "bouncehammer.jp", "listid": "", "diagnosticcode": "550 5.1.1 <userunknown@bouncehammer.jp>... User Unknown", "deliverystatus": "5.1.1", "lhost": "p0000-ipbfpfx00kyoto.kyoto.example.co.jp", "smtpagent": "Sendmail"}]
```

上記のようにSisimaiのmake()メソッドをmboxかMaildirのPATHを引数にして実行すると
解析結果が配列で返ってきます。

One-Liner | ワンライナーで
--------------------------

```shell
% ruby -rsisimai -e 'puts Sisimai.dump($*.shift)' /path/to/mbox
```

Other Information | その他の情報
================================

Related Sites | 関連サイト
--------------------------

* __libsisimai.org__ | [Sisimai — A successor to bounceHammer, Library to parse error mails](http://libsisimai.org/)
* __GitHub__ | [github.com/sisimai/rb-Sisimai](https://github.com/sisimai/rb-Sisimai)
* __Perl verson__ | [Perl version of Sisimai](https://github.com/sisimai/p5-Sisimai)

SEE ALSO | 参考サイト
---------------------
* [RFC3463 - Enhanced Mail System Status Codes](https://tools.ietf.org/html/rfc3463)
* [RFC3464 - An Extensible Message Format for Delivery Status Notifications](https://tools.ietf.org/html/rfc3464)
* [RFC3834 - Recommendations for Automatic Responses to Electronic Mail](https://tools.ietf.org/html/rfc3834)
* [RFC5321 - Simple Mail Transfer Protocol](https://tools.ietf.org/html/rfc5321)
* [RFC5322 - Internet Message Format](https://tools.ietf.org/html/rfc5322)

AUTHOR | 作者
-------------
[@azumakuniyuki](https://twitter.com/azumakuniyuki)

COPYRIGHT | 著作権
------------------
Copyright (C) 2015-2016 azumakuniyuki, All Rights Reserved.

LICENSE | ライセンス
--------------------
This software is distributed under The BSD 2-Clause License.

