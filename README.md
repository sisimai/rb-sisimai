[![License](https://img.shields.io/badge/license-BSD%202--Clause-orange.svg)](https://github.com/sisimai/rb-Sisimai/blob/master/LICENSE)
[![Coverage Status](https://img.shields.io/coveralls/sisimai/rb-Sisimai.svg)](https://coveralls.io/r/sisimai/rb-Sisimai)
[![Build Status](https://travis-ci.org/sisimai/rb-Sisimai.svg?branch=master)](https://travis-ci.org/sisimai/rb-Sisimai) 
[![Codacy Badge](https://api.codacy.com/project/badge/grade/38340177e6284a65be69c0c7c3dc2b58)](https://www.codacy.com/app/azumakuniyuki/rb-Sisimai)
[![Ruby](https://img.shields.io/badge/ruby-v2.1.0--v2.3.0-red.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/sisimai.svg)](https://badge.fury.io/rb/sisimai)

![](http://41.media.tumblr.com/45c8d33bea2f92da707f4bbe66251d6b/tumblr_nuf7bgeyH51uz9e9oo1_1280.png)

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

More details about system requirements are available at available at 
[Sisimai | Getting Started](http://libsisimai.org/start) page.

* [Ruby 2.1.0 or later](http://www.ruby-lang.org/)
* Also works on JRuby 9.0.0.0 or later

Install | インストール
----------------------

### From RubyGems.org

```shell
% sudo gem install sisimai
Fetching: sisimai-4.14.2.gem (100%)
Successfully installed sisimai-4.14.2
Parsing documentation for sisimai-4.14.2
Installing ri documentation for sisimai-4.14.2
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
sisimai 4.14.2 built to pkg/sisimai-4.14.2.gem.
sisimai (4.14.2) installed.
```

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

Differences between Perl version and Ruby version | Perl版との違い
------------------------------------------------------------------
The following table show the differences between Perl version of Sisimai
and Ruby version of Sisimai.

| Features                                       | Ruby version  | Perl version|
|------------------------------------------------|---------------|-------------|
| System requirements                            | Ruby 2.1-2.3  | Perl 5.10 - |
| Analytical precision ratio(2000 emails)[1]     | 1.00          | 1.00        |
| The speed of parsing email(1000 emails)        | 3.93s         | 2.50s       |
| How to install                                 | gem install   | cpanm       |
| Dependencies (Except core modules)             | 0 modules     | 2 modules   |
| LOC:Source lines of code                       | 11400 lines   | 8900 lines  |
| The number of tests in t/, xt/ directory       | 89570 tests   | 160500 tests|
| License                                        | The BSD 2-Clause License    |
| Support Contract provided by Developer         | Coming soon   | Available   |

1. See ./ANALYTICAL-PRECISION

公開中のPerl版Sisimai(p5-Sisimai)とRuby版Sisimai(rb-Sisimai)は下記のような違いが
あります。

| 機能                                           | Ruby version  | Perl version|
|------------------------------------------------|---------------|-------------|
| 動作環境                                       | Ruby 2.1-2.3  | Perl 5.10 - |
| 解析精度の割合(2000通のメール)[1]              | 1.00          | 1.00        |
| メール解析速度(1000通のメール)                 | 3.93秒        | 2.50秒      |
| インストール方法                               | gem install   | cpanm       |
| 依存モジュール数(コアモジュールを除く)         | 0モジュール   | 2モジュール |
| LOC:ソースコードの行数                         | 11400行       | 8900行      |
| テスト件数(t/,xt/ディレクトリ)                 | 89570件       | 160500件    |
| ライセンス                                     | 二条項BSD     | 二条項BSD   |
| 開発会社によるサポート契約                     | 準備中        | 提供中      |

1. ./ANALYTICAL-PRECISIONを参照

MTA/MSP Modules | MTA/MSPモジュール一覧
---------------------------------------
The following table is the list of MTA/MSP:(Mail Service Provider) modules. More
details about these modules are available at 
[Sisimai | Parser Engines](http://libsisimai.org/engine) page.

| Module Name(Sisimai::)   | Description                                       |
|--------------------------|---------------------------------------------------|
| MTA::Activehunter        | TransWARE Active!hunter                           |
| MTA::ApacheJames         | Java Apache Mail Enterprise Server                |
| MTA::Courier             | Courier MTA                                       |
| MTA::Domino              | IBM Domino Server                                 |
| MTA::Exchange            | Microsoft Exchange Server                         |
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
| MSP::US::Aol             | Aol Mail: http://www.aol.com                      |
| MSP::US::Bigfoot         | Bigfoot: http://www.bigfoot.com                   |
| MSP::US::Facebook        | Facebook: https://www.facebook.com                |
| MSP::US::Google          | Google Gmail: https://mail.google.com             |
| MSP::US::Outlook         | Microsoft Outlook.com: https://www.outlook.com/   |
| MSP::US::ReceivingSES    | AmazonSES(Receiving): http://aws.amazon.com/ses/  |
| MSP::US::SendGrid        | SendGrid: http://sendgrid.com/                    |
| MSP::US::Verizon         | Verizon Wireless: http://www.verizonwireless.com  |
| MSP::US::Yahoo           | Yahoo! MAIL: https://www.yahoo.com                |
| MSP::US::Zoho            | Zoho Mail: https://www.zoho.com                   |
| ARF                      | Abuse Feedback Reporting Format                   |
| RFC3464                  | Fallback Module for MTAs                          |
| RFC3834                  | Detector for auto replied message                 |

上記はSisimaiに含まれてるMTA/MSP(メールサービスプロバイダ)モジュールの一覧です。


Bounce Reason List | バウンス理由の一覧
----------------------------------------
Sisimai can detect the following 25 bounce reasons. More details about reasons
are available at [Sisimai | Bounce Reason List](http://libsisimai.org/reason)
page.

| Reason(理由)   | Description                            | 理由の説明                       |
|----------------|----------------------------------------|----------------------------------|
| Blocked        | Blocked due to client IP address       | IPアドレスによる拒否             |
| ContentError   | Invalid format email                   | 不正な形式のメール               |
| ExceedLimit    | Message size exceeded the limit(5.2.3) | メールサイズの超過               |
| Expired        | Delivery time expired                  | 配送時間切れ                     |
| Feedback       | Bounced for a complaint of the message | 元メールへの苦情によるバウンス   |
| Filtered       | Rejected after DATA command            | DATAコマンド以降で拒否された     |
| HasMoved       | Destination mail addrees has moved     | 宛先メールアドレスは移動した     |
| HostUnknown    | Unknown destination host name          | 宛先ホスト名が存在しない         |
| MailboxFull    | Recipient's mailbox is full            | メールボックスが一杯             |
| MailerError    | Mailer program error                   | メールプログラムのエラー         |
| MesgTooBig     | Message size is too big(5.3.4)         | メールが大き過ぎる               |
| NetworkError   | Network error: DNS or routing          | DNS等ネットワーク関係のエラー    |
| NotAccept      | Destinaion does not accept any message | 宛先ホストはメールを受けとらない |
| OnHold         | Deciding the bounce reason is on hold  | エラー理由の特定は保留           |
| Rejected       | Rejected due to envelope from address  | エンベロープFromで拒否された     |
| NoRelaying     | Relay access denied                    | リレーの拒否                     |
| SecurityError  | Virus detected or authentication error | ウィルスの検出または認証失敗     |
| SpamDetected   | Detected a message as spam             | メールはスパムとして判定された   |
| Suspend        | Recipient's account is suspended       | 宛先アカウントは一時的に停止中   |
| SystemError    | Some error on the destination host     | 宛先サーバでのOSレベルのエラー   |
| SystemFull     | Disk full on the destination host      | 宛先サーバのディスクが一杯       |
| TooManyConn    | Connection rate limit exceeded         | 接続制限数を超過した             |
| UserUnknown    | Recipient's address does not exist     | 宛先メールアドレスは存在しない   |
| Undefined      | Could not decide the error reason      | バウンスした理由は特定出来ず     |
| Vacation       | Auto replied message                   | 自動応答メッセージ               |

Sisimaiは上記のエラー25種を検出します。


Parsed data structure | 解析後のデータ構造
------------------------------------------
The following table shows a data structure(Sisimai::Data) of parsed bounce mail.
More details about data structure are available at available at 
[Sisimai — Data Structure of Sisimai::Data](http://libsisimai.org/data) page.

| Name           | Description                           | 値の説明                       |
|----------------|---------------------------------------|--------------------------------|
| action         | The value of Action: header           | Action:ヘッダの値              |
| addresser      | The From address                      | 送信者のアドレス               |
| alias          | Alias of the recipient                | 受信者アドレスのエイリアス     |
| destination    | The domain part of the "recipinet"    | "recipient"のドメイン部分      |
| deliverystatus | Delivery Status(DSN)                  | 配信状態(DSN)の値              |
| diagnosticcode | Error message                         | エラーメッセージ               |
| diagnostictype | Error message type                    | エラーメッセージの種別         |
| feedbacktype   | Feedback Type                         | Feedback-Typeのフィールド      |
| lhost          | local host name(local MTA)            | 送信側MTAのホスト名            |
| listid         | List-Id: header of each ML            | List-Idヘッダの値              |
| messageid      | Message-Id: of the original message   | 元メールのMessage-Id           |
| reason         | Detected bounce reason                | 検出したバウンスした理由       |
| recipient      | Recipient address which bounced       | バウンスした受信者のアドレス   |
| replycode      | SMTP Reply Code                       | SMTP応答コード                 |
| rhost          | Remote host name(remote MTA)          | 受信側MTAのホスト名            |
| senderdomain   | The domain part of the "addresser"    | "addresser"のドメイン部分      |
| softbounce     | The bounce is soft bounce or not      | ソフトバウンスであるかどうか   |
| smtpagent      | MTA name(Sisimai::MTA::, MSP::)       | MTA名(Sisimai::MTA::,MSP::)    |
| smtpcommand    | The last SMTP command in the session  | セッション中最後のSMTPコマンド |
| subject        | Subject of the original message(UTF8) | 元メールのSubject(UTF-8)       |
| timestamp      | Date: header in the original message  | 元メールのDate                 |
| timezoneoffset | Time zone offset(seconds)             | タイムゾーンの時差             |
| token          | MD5 value of addresser and recipient  | 送信者と受信者のハッシュ値     |

上記の表は解析後のバウンスメールの構造(Sisimai::Data)です。


Emails could not be parsed | 解析出来ないメール
-----------------------------------------------
__Bounce mails__ which could not be parsed by Sisimai are saved in the directory
`set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet`. If you find any
bounce email cannot be parsed using Sisimai, please add the email into the directory
and send Pull-Request to this repository.

解析出来ない__バウンスメール__は`set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet`
ディレクトリにはいっています。もしもSisimaiで解析出来ないメールを見つけたら、
このディレクトリに追加してPull-Requestを送ってください。


Other Information | その他の情報
================================

Related Sites | 関連サイト
--------------------------

* __libsisimai.org__ | [Sisimai | The successor to bounceHammer, Library to parse bounce mails](http://libsisimai.org/)
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

