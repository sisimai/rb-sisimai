![](http://libsisimai.org/static/images/logo/sisimai-x01.png)

[![License](https://img.shields.io/badge/license-BSD%202--Clause-orange.svg)](https://github.com/sisimai/rb-Sisimai/blob/master/LICENSE)
[![Coverage Status](https://img.shields.io/coveralls/sisimai/rb-Sisimai.svg)](https://coveralls.io/r/sisimai/rb-Sisimai)
[![Build Status](https://travis-ci.org/sisimai/rb-Sisimai.svg?branch=master)](https://travis-ci.org/sisimai/rb-Sisimai) 
[![Codacy Badge](https://api.codacy.com/project/badge/grade/38340177e6284a65be69c0c7c3dc2b58)](https://www.codacy.com/app/azumakuniyuki/rb-Sisimai)
[![Ruby](https://img.shields.io/badge/ruby-v2.1.0--v2.4.0-red.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/sisimai.svg)](https://badge.fury.io/rb/sisimai)

- [**README(English)**](README.md)
- [シシマイ? | What is Sisimai](#what-is-sisimai)
    - [主な特徴的機能 | Key features](#key-features)
    - [コマンドラインでのデモ | Command line demo](#command-line-demo)
- [シシマイを使う準備 | Setting Up Sisimai](#setting-up-sisimai)
    - [動作環境 | System requirements](#system-requirements)
    - [インストール | Install](#install)
        - [RubyGemsから | From RubyGems](#from-rubygems)
        - [GitHubから | From GitHub](#from-github)
- [使い方 | Usage](#usage)
    - [基本的な使い方 | Basic usage](#basic-usage)
    - [解析結果をJSONで得る | Convert to JSON](#convert-to-json)
    - [バウンスオブジェクトを読む | Read bounce object](#read-bounce-object)
    - [コールバック機能 | Callback feature](#callback-feature)
    - [ワンライナー | One-Liner](#one-liner)
    - [出力例 | Output example](#output-example)
- [シシマイの仕様 | Sisimai Specification](#sisimai-specification)
    - [Ruby版とPerl版の違い | Differences between Ruby version and Perl version](#differences-between-ruby-version-and-perl-version)
    - [その他の仕様詳細 | Other specification of Sisimai](#other-specification-of-sisimai)
- [Contributing](#contributing)
    - [バグ報告 | Bug report](#bug-report)
    - [解析できないメール | Emails could not be parsed](#emails-could-not-be-parsed)
- [その他の情報 | Other Information](#other-information)
    - [関連サイト | Related sites](#related-sites)
    - [参考情報| See also](#see-also)
- [作者 | Author](#author)
- [著作権 | Copyright](#copyright)
- [ライセンス | License](#license)

What is Sisimai
===============================================================================
Sisimai(シシマイ)はRFC5322準拠のエラーメールを解析し、解析結果をデータ構造に
変換するインターフェイスを提供するRubyライブラリです。
[github.com/sisimai/p5-Sisimai](https://github.com/sisimai/p5-Sisimai/)
で公開しているPerl版シシマイから移植しました。

![](http://libsisimai.org/static/images/figure/sisimai-overview-1.png)

Key features
-------------------------------------------------------------------------------
* __エラーメールをデータ構造に変換__
  * Rubyのデータ形式(HashとArray)とJSON(String)に対応
* __インストールも使用も簡単__
  * gem install
  * git clone & make
* __高い解析精度__
  * 解析精度はbounceHammerの2倍
  * 28種類のMTAに対応
  * 22種類の著名なMSPに対応
  * 2種類の著名なメール配信クラウドに対応(JSON)
  * Feedback Loopにも対応
  * 29種類のエラー理由を検出

Setting Up Sisimai
===============================================================================

System requirements
-------------------------------------------------------------------------------
Sisimaiの動作環境についての詳細は
[Sisimai | シシマイを使ってみる](http://libsisimai.org/ja/start)をご覧ください。


* [Ruby 2.1.0 or later](http://www.ruby-lang.org/)
  * [__Oj | The fastest JSON parser and object serializer__](https://rubygems.org/gems/oj)
* Also works on [JRuby 9.0.4.0 or later](http://jruby.org)
  * [__JrJackson | A mostly native JRuby wrapper for the java jackson json processor jar__](https://rubygems.org/gems/jrjackson)

Install
-------------------------------------------------------------------------------
### From RubyGems.org

```shell
$ sudo gem install sisimai
Fetching: sisimai-4.22.2.gem (100%)
Successfully installed sisimai-4.22.2
Parsing documentation for sisimai-4.22.2
Installing ri documentation for sisimai-4.22.2
Done installing documentation for sisimai after 6 seconds
1 gem installed
```

### From GitHub

```shell
$ cd /usr/local/src
$ git clone https://github.com/sisimai/rb-Sisimai.git
$ cd ./rb-Sisimai
$ sudo make depend install-from-local
gem install bundle rake rspec coveralls
...
4 gems installed
bundle exec rake install
sisimai 4.22.2 built to pkg/sisimai-4.22.2.gem.
sisimai (4.22.2) installed.
```

Usage
======

Basic usage
-------------------------------------------------------------------------------
下記のようにSisimaiの`make()`メソッドをmboxかMaildirのPATHを引数にして実行すると
解析結果が配列で返ってきます。

```ruby
#! /usr/bin/env ruby
require 'sisimai'
v = Sisimai.make('/path/to/mbox')       # or path to Maildir/

# If you want to get bounce records which reason is "delivered", set "delivered"
# option to make() method like the following:
v = Sisimai.make('/path/to/mbox', delivered: true)

if v.is_a? Array
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
```

Convert to JSON
-------------------------------------------------------------------------------
下記のようにSisimaiの`dump()`メソッドをmboxかMaildirのPATHを引数にして実行すると
解析結果が文字列(JSON)で返ってきます。

```ruby
# Get JSON string from parsed mailbox or Maildir/
puts Sisimai.dump('/path/to/mbox')  # or path to Maildir/

# dump() method also accepts "delivered" option like the following code:
puts Sisimai.dump('/path/to/mbox', delivered: true)
```

Read bounce object
-------------------------------------------------------------------------------
メール配信クラウドからAPIで取得したバウンスオブジェクト(JSON)を読んで解析する
場合は、次のようなコードを書いてください。この機能はSisimai v4.20.0で実装され
ました。

```ruby
#! /usr/bin/env ruby
require 'json'
require 'sisimai'

j = JSON.load('{"notificationType"=>"Bounce", "bounce"=>{"...') # JSON String
v = Sisimai.make(j, input: 'json')

if v.is_a? Array
  v.each do |e|
    ...
  end
end
```
現時点ではAmazon SESとSendGridのみをサポートしています。

Callback feature
-------------------------------------------------------------------------------
Sisimai 4.19.0から`Sisimai.make()`と`Sisimai.dump()`にLamda(Procオブジェクト)
を引数`hook`に指定できるコールバック機能が実装されました。
`hook`に指定したコードによって処理された結果は`Sisimai::Data.catch`
メソッドで得ることができます。

```ruby
#! /usr/bin/env ruby
require 'sisimai'
callbackto = lambda do |v|
  r = { 'x-mailer' => '', 'queue-id' => '' }

  if cv = v['message'].match(/^X-Postfix-Queue-ID:\s*(.+)$/)
    r['queue-id'] = cv[1]
  end
  r['x-mailer'] = v['headers']['x-mailer'] || ''
  return r
end

list = ['X-Mailer']
data = Sisimai.make('/path/to/mbox', hook: callbackto, field: list)
json = Sisimai.dump('/path/to/mbox', hook: callbackto, field: list)

puts data[0].catch['x-mailer']      # Apple Mail (2.1283)
```

コールバック機能のより詳細な使い方は
[Sisimai | 解析方法 - コールバック機能](http://libsisimai.org/ja/usage/#callback)
をご覧ください。


One-Liner
-------------------------------------------------------------------------------

```shell
$ ruby -rsisimai -e 'puts Sisimai.dump($*.shift)' /path/to/mbox
```

Output example
-------------------------------------------------------------------------------
![](http://libsisimai.org/static/images/demo/sisimai-dump-02.gif)

```json
[{"recipient": "kijitora@example.jp", "addresser": "shironeko@1jo.example.org", "feedbacktype": "", "action": "failed", "subject": "Nyaaaaan", "smtpcommand": "DATA", "diagnosticcode": "550 Unknown user kijitora@example.jp", "listid": "", "destination": "example.jp", "smtpagent": "Email::Courier", "lhost": "1jo.example.org", "deliverystatus": "5.0.0", "timestamp": 1291954879, "messageid": "201012100421.oBA4LJFU042012@1jo.example.org", "diagnostictype": "SMTP", "timezoneoffset": "+0900", "reason": "filtered", "token": "ce999a4c869e3f5e4d8a77b2e310b23960fb32ab", "alias": "", "senderdomain": "1jo.example.org", "rhost": "mfsmax.example.jp"}, {"diagnostictype": "SMTP", "timezoneoffset": "+0900", "reason": "userunknown", "timestamp": 1381900535, "messageid": "E1C50F1B-1C83-4820-BC36-AC6FBFBE8568@example.org", "token": "9fe754876e9133aae5d20f0fd8dd7f05b4e9d9f0", "alias": "", "senderdomain": "example.org", "rhost": "mx.bouncehammer.jp", "action": "failed", "addresser": "kijitora@example.org", "recipient": "userunknown@bouncehammer.jp", "feedbacktype": "", "smtpcommand": "DATA", "subject": "バウンスメールのテスト(日本語)", "destination": "bouncehammer.jp", "listid": "", "diagnosticcode": "550 5.1.1 <userunknown@bouncehammer.jp>... User Unknown", "deliverystatus": "5.1.1", "lhost": "p0000-ipbfpfx00kyoto.kyoto.example.co.jp", "smtpagent": "Email::Sendmail"}]
```

Sisimai Specification
===============================================================================

Differences between Ruby version and Perl version
-------------------------------------------------------------------------------
公開中のPerl版Sisimai(p5-Sisimai)とRuby版Sisimai(rb-Sisimai)は下記のような違いが
あります。bounceHammer 2.7.13p3とSisimai(シシマイ)の違いについては
[Sisimai | 違いの一覧](http://libsisimai.org/ja/diff)をご覧ください。

| 機能                                        | Ruby version   | Perl version  |
|---------------------------------------------|----------------|---------------|
| 動作環境                                    | Ruby 2.1 - 2.4 | Perl 5.10 -   |
|                                             | JRuby 9.0.4.0- |               |
| 解析精度の割合(2000通のメール)[1]           | 1.00           | 1.00          |
| メール解析速度(1000通のメール)              | 6.70秒         | 2.10秒        |
| インストール方法                            | gem install    | cpanm, cpm    |
| 依存モジュール数(コアモジュールを除く)      | 1モジュール    | 2モジュール   |
| LOC:ソースコードの行数                      | 13000行        | 9800行        |
| テスト件数(spec/,t/,xt/ディレクトリ)        | 213000件       | 230000件      |
| ライセンス                                  | 二条項BSD      | 二条項BSD     |
| 開発会社によるサポート契約                  | 準備中         | 提供中        |

1. [./ANALYTICAL-PRECISION](https://github.com/sisimai/rb-Sisimai/blob/master/ANALYTICAL-PRECISION)を参照

Other spec of Sisimai
-------------------------------------------------------------------------------
- [**解析モジュールの一覧**](http://libsisimai.org/ja/engine)
- [**バウンス理由の一覧**](http://libsisimai.org/ja/reason)
- [**Sisimai::Dataのデータ構造**](http://libsisimai.org/ja/data)

Contributing
===============================================================================

Bug report
-------------------------------------------------------------------------------
もしもSisimaiにバグを発見した場合は[Issues](https://github.com/sisimai/rb-Sisimai/issues)
にて連絡をいただけると助かります。

Emails could not be parsed
-------------------------------------------------------------------------------
Sisimaiで解析できないバウンスメールは
[set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet](https://github.com/sisimai/set-of-emails/tree/master/to-be-debugged-because/sisimai-cannot-parse-yet)リポジトリに追加してPull-Requestを送ってください。

Other Information
===============================================================================

Related sites
-------------------------------------------------------------------------------
* __@libsisimai__ | [Sisimai on Twitter (@libsisimai)](https://twitter.com/libsisimai)
* __libSISIMAI.ORG__ | [Sisimai | The successor to bounceHammer, Library to parse bounce mails](http://libsisimai.org/)
* __Sisimai Blog__ | [blog.libsisimai.org](http://blog.libsisimai.org/)
* __Facebook Page__ | [facebook.com/libsisimai](https://www.facebook.com/libsisimai/)
* __GitHub__ | [github.com/sisimai/rb-Sisimai](https://github.com/sisimai/rb-Sisimai)
* __RubyGems.org__ | [rubygems.org/gems/sisimai](https://rubygems.org/gems/sisimai)
* __Perl verson__ | [Perl version of Sisimai](https://github.com/sisimai/p5-Sisimai)
* __Fixtures__ | [set-of-emails - Sample emails for "make test"](https://github.com/sisimai/set-of-emails)

See also
-------------------------------------------------------------------------------
* [README.md - README.md in English](https://github.com/sisimai/rb-Sisimai/blob/master/README.md)
* [RFC3463 - Enhanced Mail System Status Codes](https://tools.ietf.org/html/rfc3463)
* [RFC3464 - An Extensible Message Format for Delivery Status Notifications](https://tools.ietf.org/html/rfc3464)
* [RFC3834 - Recommendations for Automatic Responses to Electronic Mail](https://tools.ietf.org/html/rfc3834)
* [RFC5321 - Simple Mail Transfer Protocol](https://tools.ietf.org/html/rfc5321)
* [RFC5322 - Internet Message Format](https://tools.ietf.org/html/rfc5322)

Author
===============================================================================
[@azumakuniyuki](https://twitter.com/azumakuniyuki)

Copyright
===============================================================================
Copyright (C) 2015-2017 azumakuniyuki, All Rights Reserved.

License
===============================================================================
This software is distributed under The BSD 2-Clause License.

