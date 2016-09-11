[![License](https://img.shields.io/badge/license-BSD%202--Clause-orange.svg)](https://github.com/sisimai/rb-Sisimai/blob/master/LICENSE)
[![Coverage Status](https://img.shields.io/coveralls/sisimai/rb-Sisimai.svg)](https://coveralls.io/r/sisimai/rb-Sisimai)
[![Build Status](https://travis-ci.org/sisimai/rb-Sisimai.svg?branch=master)](https://travis-ci.org/sisimai/rb-Sisimai) 
[![Codacy Badge](https://api.codacy.com/project/badge/grade/38340177e6284a65be69c0c7c3dc2b58)](https://www.codacy.com/app/azumakuniyuki/rb-Sisimai)
[![Ruby](https://img.shields.io/badge/ruby-v2.1.0--v2.3.0-red.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/sisimai.svg)](https://badge.fury.io/rb/sisimai)

![](http://41.media.tumblr.com/45c8d33bea2f92da707f4bbe66251d6b/tumblr_nuf7bgeyH51uz9e9oo1_1280.png)

シシマイ?
=========
Sisimai(シシマイ)はRFC5322準拠のエラーメールを解析し、解析結果をデータ構造に
変換するインターフェイスを提供するRubyライブラリです。
[github.com/sisimai/p5-Sisimai](https://github.com/sisimai/p5-Sisimai/)
で公開しているPerl版シシマイから移植しました。

主な特徴的機能
--------------
* __エラーメールをデータ構造に変換__
  * Perlのデータ形式とJSONに対応
* __インストールも使用も簡単__
  * gem install
  * git clone & make
* __高い解析精度__
  * 解析精度はbounceHammerの二倍
  * 27種類のMTAに対応
  * 21種類の著名なMSPに対応
  * Feedback Loopにも対応
  * 27種類のエラー理由を検出

シシマイを使う準備
==================
動作環境
--------
Sisimaiの動作環境についての詳細は
[Sisimai | シシマイを使ってみる](http://libsisimai.org/ja/start)をご覧ください。


* [Ruby 2.1.0 or later](http://www.ruby-lang.org/)
  * [__Oj | The fastest JSON parser and object serializer__](https://rubygems.org/gems/oj)
* Also works on [JRuby 9.0.4.0 or later](http://jruby.org)
  * [__JrJackson | A mostly native JRuby wrapper for the java jackson json processor jar__](https://rubygems.org/gems/jrjackson)

インストール
------------
### From RubyGems.org

```shell
% sudo gem install sisimai
Fetching: sisimai-4.16.0.gem (100%)
Successfully installed sisimai-4.16.0
Parsing documentation for sisimai-4.16.0
Installing ri documentation for sisimai-4.16.0
Done installing documentation for sisimai after 6 seconds
1 gem installed
```

### From GitHub

```shell
% cd /usr/local/src
% git clone https://github.com/sisimai/rb-Sisimai.git
% cd ./rb-Sisimai
% sudo make depend install-from-local
gem install bundle rake rspec coveralls
Successfully installed bundle-0.0.1
Parsing documentation for bundle-0.0.1
Done installing documentation for bundle after 0 seconds
Successfully installed rake-10.5.0
Parsing documentation for rake-10.5.0
Done installing documentation for rake after 1 seconds
Successfully installed rspec-3.4.0
Parsing documentation for rspec-3.4.0
Done installing documentation for rspec after 0 seconds
Successfully installed coveralls-0.8.10
Parsing documentation for coveralls-0.8.10
Done installing documentation for coveralls after 0 seconds
4 gems installed
bundle exec rake install
sisimai 4.14.2 built to pkg/sisimai-4.16.0.gem.
sisimai (4.14.2) installed.
```

使い方
======
基本的な使い方
--------------
下記のようにSisimaiの`make()`メソッドをmboxかMaildirのPATHを引数にして実行すると
解析結果が配列で返ってきます。

```ruby
#! /usr/bin/env ruby
require 'sisimai'
v = Sisimai.make('/path/to/mbox')       # or path to Maildir/

# If you want to get bounce records which reason is "delivered", set "delivered"
# option to make() method like the following:
v = Sisimai.make('/path/to/mbox', delivered: true)

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

# dump() method also accepts "delivered" option like the following code:
puts Sisimai.dump('/path/to/mbox', delivered: true)
```

```json
[{"recipient": "kijitora@example.jp", "addresser": "shironeko@1jo.example.org", "feedbacktype": "", "action": "failed", "subject": "Nyaaaaan", "smtpcommand": "DATA", "diagnosticcode": "550 Unknown user kijitora@example.jp", "listid": "", "destination": "example.jp", "smtpagent": "Courier", "lhost": "1jo.example.org", "deliverystatus": "5.0.0", "timestamp": 1291954879, "messageid": "201012100421.oBA4LJFU042012@1jo.example.org", "diagnostictype": "SMTP", "timezoneoffset": "+0900", "reason": "filtered", "token": "ce999a4c869e3f5e4d8a77b2e310b23960fb32ab", "alias": "", "senderdomain": "1jo.example.org", "rhost": "mfsmax.example.jp"}, {"diagnostictype": "SMTP", "timezoneoffset": "+0900", "reason": "userunknown", "timestamp": 1381900535, "messageid": "E1C50F1B-1C83-4820-BC36-AC6FBFBE8568@example.org", "token": "9fe754876e9133aae5d20f0fd8dd7f05b4e9d9f0", "alias": "", "senderdomain": "example.org", "rhost": "mx.bouncehammer.jp", "action": "failed", "addresser": "kijitora@example.org", "recipient": "userunknown@bouncehammer.jp", "feedbacktype": "", "smtpcommand": "DATA", "subject": "バウンスメールのテスト(日本語)", "destination": "bouncehammer.jp", "listid": "", "diagnosticcode": "550 5.1.1 <userunknown@bouncehammer.jp>... User Unknown", "deliverystatus": "5.1.1", "lhost": "p0000-ipbfpfx00kyoto.kyoto.example.co.jp", "smtpagent": "Sendmail"}]
```

ワンライナーで
--------------

```shell
% ruby -rsisimai -e 'puts Sisimai.dump($*.shift)' /path/to/mbox
```

Perl版Sisimaiとの違い
---------------------
公開中のPerl版Sisimai(p5-Sisimai)とRuby版Sisimai(rb-Sisimai)は下記のような違いが
あります。bounceHammer version 2.7.13p3とSisimai(シシマイ)の違いについては
[Sisimai | 違いの一覧](http://libsisimai.org/ja/diff)をご覧ください。

| 機能                                        | Ruby version   | Perl version  |
|---------------------------------------------|----------------|---------------|
| 動作環境                                    | Ruby 2.1-2.3   | Perl 5.10 -   |
|                                             | JRuby 9.0.4.0- |               |
| 解析精度の割合(2000通のメール)[1]           | 1.00           | 1.00          |
| メール解析速度(1000通のメール)              | 3.30秒         | 2.33秒        |
| インストール方法                            | gem install    | cpanm         |
| 依存モジュール数(コアモジュールを除く)      | 1モジュール    | 2モジュール   |
| LOC:ソースコードの行数                      | 11600行        | 8500行        |
| テスト件数(t/,xt/ディレクトリ)              | 97000件        | 177000件      |
| ライセンス                                  | 二条項BSD      | 二条項BSD     |
| 開発会社によるサポート契約                  | 準備中         | 提供中        |

1. [./ANALYTICAL-PRECISION](https://github.com/sisimai/rb-Sisimai/blob/master/ANALYTICAL-PRECISION)を参照

MTA/MSPモジュール一覧
---------------------
下記はSisimaiに含まれてるMTA/MSP(メールサービスプロバイダ)モジュールの一覧です。
より詳しい情報は[Sisimai | 解析エンジン](http://libsisimai.org/ja/engine)を
ご覧ください。

| Module Name(Sisimai::)   | Description                                       |
|--------------------------|---------------------------------------------------|
| MTA::Activehunter        | TransWARE Active!hunter                           |
| MTA::ApacheJames         | Java Apache Mail Enterprise Server                |
| MTA::Courier             | Courier MTA                                       |
| MTA::Domino              | IBM Domino Server                                 |
| MTA::Exchange2003        | Microsoft Exchange Server 2003                    |
| MTA::Exchange2007        | Microsoft Exchange Server 2007 (> v4.18.0)        |
| MTA::Exim                | Exim                                              |
| MTA::IMailServer         | IPSWITCH IMail Server                             |
| MTA::InterScanMSS        | Trend Micro InterScan Messaging Security Suite    |
| MTA::MXLogic             | McAfee SaaS                                       |
| MTA::MailFoundry         | MailFoundry                                       |
| MTA::MailMarshalSMTP     | Trustwave Secure Email Gateway                    |
| MTA::McAfee              | McAfee Email Appliance                            |
| MTA::MessagingServer     | Oracle Communications Messaging Server            |
| MTA::MFILTER             | Digital Arts m-FILTER                             |
| MTA::Notes               | Lotus Notes                                       |
| MTA::OpenSMTPD           | OpenSMTPD                                         |
| MTA::Postfix             | Postfix                                           |
| MTA::Qmail               | qmail                                             |
| MTA::Sendmail            | V8Sendmail: /usr/sbin/sendmail                    |
| MTA::SurfControl         | WebSense SurfControl                              |
| MTA::V5sendmail          | Sendmail version 5                                |
| MTA::X1                  | Unknown MTA #1                                    |
| MTA::X2                  | Unknown MTA #2                                    |
| MTA::X3                  | Unknown MTA #3                                    |
| MTA::X4                  | Unknown MTA #4 qmail clones                       |
| MTA::X5                  | Unknown MTA #5                                    |
| MSP::DE::EinsUndEins     | 1&1: http://www.1and1.de                          |
| MSP::DE::GMX             | GMX: http://www.gmx.net                           |
| MSP::JP::Biglobe         | BIGLOBE: http://www.biglobe.ne.jp                 |
| MSP::JP::EZweb           | au EZweb: http://www.au.kddi.com/mobile/          |
| MSP::JP::KDDI            | au by KDDI: http://www.au.kddi.com                |
| MSP::RU::MailRu          | @mail.ru: https://mail.ru                         |
| MSP::RU::Yandex          | Yandex.Mail: http://www.yandex.ru                 |
| MSP::UK::MessageLabs     | Symantec.cloud http://www.messagelabs.com         |
| MSP::US::AmazonSES       | AmazonSES(Sending): http://aws.amazon.com/ses/    |
| MSP::US::AmazonWorkMail  | Amazon WorkMail: https://aws.amazon.com/workmail/ |
| MSP::US::Aol             | Aol Mail: http://www.aol.com                      |
| MSP::US::Bigfoot         | Bigfoot: http://www.bigfoot.com                   |
| MSP::US::Facebook        | Facebook: https://www.facebook.com                |
| MSP::US::Google          | Google Gmail: https://mail.google.com             |
| MSP::US::Office365       | Microsoft Office 365: http://office.microsoft.com/|
| MSP::US::Outlook         | Microsoft Outlook.com: https://www.outlook.com/   |
| MSP::US::ReceivingSES    | AmazonSES(Receiving): http://aws.amazon.com/ses/  |
| MSP::US::SendGrid        | SendGrid: http://sendgrid.com/                    |
| MSP::US::Verizon         | Verizon Wireless: http://www.verizonwireless.com  |
| MSP::US::Yahoo           | Yahoo! MAIL: https://www.yahoo.com                |
| MSP::US::Zoho            | Zoho Mail: https://www.zoho.com                   |
| ARF                      | Abuse Feedback Reporting Format                   |
| RFC3464                  | Fallback Module for MTAs                          |
| RFC3834                  | Detector for auto replied message                 |

バウンス理由の一覧
------------------
Sisimaiは下記のエラー27種を検出します。バウンス理由についてのより詳細な情報は
[Sisimai | バウンス理由の一覧](http://libsisimai.org/ja/reason)をご覧ください。

| バウンス理由   | 理由の説明                                 | 実装バージョン |
|----------------|--------------------------------------------|----------------|
| Blocked        | IPアドレスやホスト名による拒否             |                |
| ContentError   | 不正な形式のヘッダまたはメール             |                |
| Delivered[1]   | 正常に配信された                           | v4.16.0        |
| ExceedLimit    | メールサイズの超過                         |                |
| Expired        | 配送時間切れ                               |                |
| Feedback       | 元メールへの苦情によるバウンス(FBL形式の)  |                |
| Filtered       | DATAコマンド以降で拒否された               |                |
| HasMoved       | 宛先メールアドレスは移動した               |                |
| HostUnknown    | 宛先ホスト名が存在しない                   |                |
| MailboxFull    | メールボックスが一杯                       |                |
| MailerError    | メールプログラムのエラー                   |                |
| MesgTooBig     | メールが大き過ぎる                         |                |
| NetworkError   | DNS等ネットワーク関係のエラー              |                |
| NotAccept      | 宛先ホストはメールを受けとらない           |                |
| OnHold         | エラー理由の特定は保留                     |                |
| Rejected       | エンベロープFromで拒否された               |                |
| NoRelaying     | リレーの拒否                               |                |
| SecurityError  | ウィルスの検出または認証失敗               |                |
| SpamDetected   | メールはスパムとして判定された             |                |
| Suspend        | 宛先アカウントは一時的に停止中             |                |
| SyntaxError    | SMTPの文法エラー                           | v4.17.0        |
| SystemError    | 宛先サーバでのOSレベルのエラー             |                |
| SystemFull     | 宛先サーバのディスクが一杯                 |                |
| TooManyConn    | 接続制限数を超過した                       |                |
| UserUnknown    | 宛先メールアドレスは存在しない             |                |
| Undefined      | バウンスした理由は特定出来ず               |                |
| Vacation       | 自動応答メッセージ                         | v4.1.28        |

1. このバウンス理由は標準では解析結果に含まれません


解析後のデータ構造
------------------
下記の表は解析後のバウンスメールの構造(`Sisimai::Data`)です。データ構造のより詳細な情報は
[Sisimai | Sisimai::Dataのデータ構造](http://libsisimai.org/ja/data)をご覧ください。

| アクセサ名     | 値の説明                                                    |
|----------------|-------------------------------------------------------------|
| action         | Action:ヘッダの値                                           |
| addresser      | 送信者のアドレス                                            |
| alias          | 受信者アドレスのエイリアス                                  |
| destination    | "recipient"のドメイン部分                                   |
| deliverystatus | 配信状態(DSN)の値(例: 5.1.1, 4.4.7)                         |
| diagnosticcode | エラーメッセージ                                            |
| diagnostictype | エラーメッセージの種別                                      |
| feedbacktype   | Feedback-Typeのフィールド                                   |
| lhost          | 送信側MTAのホスト名                                         |
| listid         | 本メールのList-Idヘッダの値                                 |
| messageid      | 元メールのMessage-Idヘッダの値                              |
| reason         | 検出したバウンスした理由                                    |
| recipient      | バウンスした受信者のアドレス                                |
| replycode      | SMTP応答コード(例: 550, 421)                                |
| rhost          | 受信側MTAのホスト名                                         |
| senderdomain   | "addresser"のドメイン部分                                   |
| softbounce     | ソフトバウンスであるかどうか(0=hard,1=soft,-1=不明)         |
| smtpagent      | 解析に使用したMTA/MSPのモジュール名(Sisimai::MTA::,MSP::)   |
| smtpcommand    | セッション中最後のSMTPコマンド                              |
| subject        | 元メールのSubjectヘッダの値(UTF-8)                          |
| timestamp      | バウンスした日時(UNIXマシンタイム)                          |
| timezoneoffset | タイムゾーンの時差(例:+0900)                                |
| token          | 送信者と受信者・時刻から作られるハッシュ値                  |

解析出来ないメール
------------------
解析出来ないバウンスメールは`set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet`
ディレクトリにはいっています。もしもSisimaiで解析出来ないメールを見つけたら、
このディレクトリに追加してPull-Requestを送ってください。

その他の情報
============
関連サイト
----------
* __@libsisimai__ | [Sisimai on Twitter (@libsisimai)](https://twitter.com/libsisimai)
* __libsisimai.org__ | [Sisimai | The successor to bounceHammer, Library to parse bounce mails](http://libsisimai.org/)
* __GitHub__ | [github.com/sisimai/rb-Sisimai](https://github.com/sisimai/rb-Sisimai)
* __Perl verson__ | [Perl version of Sisimai](https://github.com/sisimai/p5-Sisimai)

参考情報
--------
* [README.md - README.md in English](https://github.com/sisimai/rb-Sisimai/blob/master/README.md)
* [RFC3463 - Enhanced Mail System Status Codes](https://tools.ietf.org/html/rfc3463)
* [RFC3464 - An Extensible Message Format for Delivery Status Notifications](https://tools.ietf.org/html/rfc3464)
* [RFC3834 - Recommendations for Automatic Responses to Electronic Mail](https://tools.ietf.org/html/rfc3834)
* [RFC5321 - Simple Mail Transfer Protocol](https://tools.ietf.org/html/rfc5321)
* [RFC5322 - Internet Message Format](https://tools.ietf.org/html/rfc5322)

作者
----
[@azumakuniyuki](https://twitter.com/azumakuniyuki)

著作権
------
Copyright (C) 2015-2016 azumakuniyuki, All Rights Reserved.

ライセンス
----------
This software is distributed under The BSD 2-Clause License.

