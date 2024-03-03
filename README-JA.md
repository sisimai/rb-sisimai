![](https://libsisimai.org/static/images/logo/sisimai-x01.png)
[![License](https://img.shields.io/badge/license-BSD%202--Clause-orange.svg)](https://github.com/sisimai/rb-sisimai/blob/master/LICENSE)
[![Coverage Status](https://img.shields.io/coveralls/sisimai/rb-sisimai.svg)](https://coveralls.io/r/sisimai/rb-sisimai)
[![Ruby](https://img.shields.io/badge/ruby-v2.4.0--v3.3.0-red.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/sisimai.svg)](https://badge.fury.io/rb/sisimai)

> [!IMPORTANT]
> **2024年2月2日の時点でこのリポジトリのデフォルトブランチは[5-stable](https://github.com/sisimai/rb-sisimai/tree/5-stable)
> (Sisimai 5)になりました。** もし古いバージョンを使いたい場合は[4-stable](https://github.com/sisimai/rb-sisimai/tree/4-stable)[^1]
> ブランチを見てください。また`main`や`master`ブランチはもうこのリポジトリでは使用していません。
[^1]: 4系を`clone`する場合は`git clone -b 4-stable https://github.com/sisimai/rb-sisimai.git`

> [!WARNING]
> Sisimai 5はRuby 2.4以上が必要です。インストール/アップグレードを実行する前に`ruby -v`コマンドで
> システムに入っているRubyのバージョンを確認してください。

> [!NOTE]
> SisimaiはPerlモジュールまたはRuby Gemですが、PHPやPython、GoやRustなどJSONを読める言語であれば
> どのような環境においても解析結果を得ることでバウンスの発生状況を捉えるのにとても有用です。

- [**README(English)**](README.md)
- [シシマイ? | What is Sisimai](#what-is-sisimai)
    - [主な特徴的機能 | The key features](#the-key-features-of-sisimai)
    - [コマンドラインでのデモ | Command line demo](#command-line-demo)
- [シシマイを使う準備 | Setting Up Sisimai](#setting-up-sisimai)
    - [動作環境 | System requirements](#system-requirements)
    - [インストール | Install](#install)
        - [RubyGemsから | From RubyGems](#from-rubygems)
        - [GitHubから | From GitHub](#from-github)
- [使い方 | Usage](#usage)
    - [基本的な使い方 | Basic usage](#basic-usage)
    - [解析結果をJSONで得る | Convert to JSON](#convert-to-json)
    - [コールバック機能 | Callback feature](#callback-feature)
    - [ワンライナー | One-Liner](#one-liner)
    - [出力例 | Output example](#output-example)
- [Sisimai 4とSisimai 5の違い](#differences-between-sisimai-4-and-sisimai-5)
    - [機能など](#features)
    - [解析メソッド](#decoding-methods)
    - [MTA/ESPモジュール](#mtaesp-module-names)
    - [バウンス理由](#bounce-reasons)
- [Contributing](#contributing)
    - [バグ報告 | Bug report](#bug-report)
    - [解析できないメール | Emails could not be decoded](#emails-could-not-be-decoded)
- [その他の情報 | Other Information](#other-information)
    - [関連サイト | Related sites](#related-sites)
    - [参考情報| See also](#see-also)
- [作者 | Author](#author)
- [著作権 | Copyright](#copyright)
- [ライセンス | License](#license)

What is Sisimai
===================================================================================================
Sisimai(シシマイ)は複雑で多種多様なバウンスメールを解析してバウンスした理由や宛先メールアドレスなど
配信が失敗した結果を構造化データで出力するライブラリでJSONでの出力も可能です。Ruby版シシマイは
[github.com/sisimai/p5-sisimai](https://github.com/sisimai/p5-sisimai/)で公開しているPerl版シシマイ
から移植しました。

![](https://libsisimai.org/static/images/figure/sisimai-overview-2.png)

The key features of Sisimai
---------------------------------------------------------------------------------------------------
* __バウンスメールを構造化したデータに変換__
  * 以下24項目の情報を含むデータ構造[^2]
    * __基本的情報__: `timestamp`, `origin`
    * __発信者情報__: `addresser`, `senderdomain`, 
    * __受信者情報__: `recipient`, `destination`, `alias`
    * __配信の情報__: `action`, `replycode`,`action`, `replycode`, `deliverystatus`
    * __エラー情報__: `reason`, `diagnosticcode`, `diagnostictype`, `feedbacktype`, `hardbounce`
    * __メール情報__: `subject`, `messageid`, `listid`,
    * __その他情報__: `smtpagent`, `timezoneoffset`, `lhost`, `rhost`, `token`, `catch`
  * __出力可能な形式__
    * Ruby (Hash, Array)
    * JSON 
      * ([`oj`](https://rubygems.org/gems/oj)を使用(CRuby))
      * ~~([`jrjackson`](https://rubygems.org/gems/jrjackson)を使用(JRuby))~~
    * YAML ([`yaml`](https://rubygems.org/gems/yaml)が必要)
  * __インストールも使用も簡単__
    * `gem install`
    * `git clone && make`
  * __高い解析精度__
    * [70種類のMTAs/MDAs/ESPs](https://libsisimai.org/en/engine/)に対応
    * Feedback Loop(ARF)にも対応
    * [34種類のバウンス理由](https://libsisimai.org/en/reason/)を検出

[^2]: コールバック機能を使用すると`catch`アクセサの下に独自のデータを追加できます


Command line demo
---------------------------------------------------------------------------------------------------
次の画像のように、Ruby版シシマイ(rb-sisimai)はコマンドラインから簡単にバウンスメールを解析すること
ができます。
![](https://libsisimai.org/static/images/demo/sisimai-5-cli-dump-r01.gif)


Setting Up Sisimai
===================================================================================================
System requirements
---------------------------------------------------------------------------------------------------
Sisimaiの動作環境についての詳細は[Sisimai | シシマイを使ってみる](https://libsisimai.org/ja/start/)
をご覧ください。


* [Ruby 2.4.0 or later](http://www.ruby-lang.org/)
  * [__oj | The fastest JSON parser and object serializer__](https://rubygems.org/gems/oj)
* ~~Also works on [JRuby 9.0.4.0 - 9.1.17.0](http://jruby.org)~~
  * ~~[__jrjackson | A mostly native JRuby wrapper for the java jackson json processor jar__](https://rubygems.org/gems/jrjackson)~~
  * [Is anyone running Sisimai on JRuby ?](https://github.com/sisimai/rb-sisimai/issues/267)

Install
---------------------------------------------------------------------------------------------------
### From RubyGems.org
```shell
$ sudo gem install sisimai
Fetching: sisimai-5.0.1.gem (100%)
Successfully installed sisimai-5.0.1
Parsing documentation for sisimai-5.0.1
Installing ri documentation for sisimai-5.0.1
Done installing documentation for sisimai after 6 seconds
1 gem installed
```

### From GitHub
> [!WARNING]
> Sisimai 5はRuby 2.4以上が必要です。インストール/アップグレードを実行する前に`ruby -v`コマンドで
> システムに入っているRubyのバージョンを確認してください。

```shell
% ruby -v
ruby 3.3.0 (2023-12-25 revision 5124f9ac75) [x86_64-darwin21]

$ cd /usr/local/src
$ git clone https://github.com/sisimai/rb-sisimai.git

$ cd ./rb-sisimai
$ sudo make depend install-from-local
gem install bundle rake minitest
...
3 gems installed
if [ -d "/usr/local/jr" ]; then \
		PATH="/usr/local/jr/bin:$PATH" /usr/local/jr/bin/gem install bundle rake minitest; \
	fi
...
3 gems installed
/opt/local/bin/rake install
sisimai 5.0.0 built to pkg/sisimai-5.0.0.gem.
sisimai (5.0.0) installed.
if [ -d "/usr/local/jr" ]; then \
		PATH="/usr/local/jr/bin:$PATH" /usr/local/jr/bin/rake install; \
	fi
sisimai 5.0.0 built to pkg/sisimai-5.0.0-java.gem.
sisimai (5.0.0) installed.
```

Usage
======
Basic usage
---------------------------------------------------------------------------------------------------
下記のようにSisimaiの`rise()`メソッドをmboxかMaildirのPATHを引数にして実行すると解析結果が配列で
返ってきます。v4.25.6から元データとなった電子メールファイルへのPATHを保持する`origin`が利用できます。

```ruby
#! /usr/bin/env ruby
require 'sisimai'
v = Sisimai.rise('/path/to/mbox')       # またはMaildir/へのPATH

# v4.23.0からSisimaiクラスのrise()メソッドとdump()メソッドはPATH以外にもバウンスメール全体を文字列
# として読めるようになりました
f = File.open('/path/to/mbox', 'r');    # またはMaildir/へのPATH
v = Sisimai.rise(f.read)

# もし"delivered"(配信成功)となる解析結果も必要な場合は以下に示すとおりrise()メソッドに"delivered"
# オプションを指定してください
v = Sisimai.rise('/path/to/mbox', delivered: true)

# v5.0.0からSisimaiはバウンス理由が"vacation"となる解析結果をデフォルトで返さなくなりました。もし
# "vacation"となる解析結果も必要な場合は次のコードで示すようにrise()メソッドに"vacation"オプション
# を指定してください。
v = Sisimai.rise('/path/to/mbox', vacation: true);

if v.is_a? Array
  v.each do |e|
    puts e.class                # Sisimai::Fact
    puts e.recipient.class      # Sisimai::Address
    puts e.timestamp.class      # Sisimai::Time

    puts e.addresser.address    # "michitsuna@example.org" # From
    puts e.recipient.address    # "kijitora@example.jp"    # To
    puts e.recipient.host       # "example.jp"
    puts e.deliverystatus       # "5.1.1"
    puts e.replycode            # "550"
    puts e.reason               # "userunknown"
    puts e.origin               # "/var/spool/bounce/Maildir/new/1740074341.eml"
    puts e.hardbounce           # true

    h = e.damn                  # Hashに変換
    j = e.dump('json')          # JSON(文字列)に変換
    puts e.dump('json')         # JSON化したバウンスメールの解析結果を表示
  end
end
```

Convert to JSON
---------------------------------------------------------------------------------------------------
下記のようにSisimaiの`dump()`メソッドをmboxかMaildirのPATHを引数にして実行すると解析結果が文字列
(JSON)で返ってきます。

```ruby
# メールボックスまたはMaildir/から解析した結果をJSONにする
puts Sisimai.dump('/path/to/mbox')  # またはMaildir/へのPATH

# dump()メソッドは"delivered"オプションや"vacation"オプションも指定可能
puts Sisimai.dump('/path/to/mbox', delivered: true, vacation: true)
```

Callback feature
---------------------------------------------------------------------------------------------------
`Sisimai.rise`と`Sisimai.dump`の`:c___`引数(`c`と`_`が三個/魚用の釣り針に見える)はコールバック機能
で呼び出される`Proc`オブジェクトを保持する配列です。`:c___`の1番目の要素には`Sisimai::Message.sift`
で呼び出される`Proc`オブジェクトでメールヘッダと本文に対して行う処理を、2番目の要素には、解析対象の
メールファイルに対して行う処理をそれぞれ入れます。

各Procオブジェクトで処理した結果は`Sisimai::Fact.catch`を通して得られます。

### [0] メールヘッダと本文に対して
`:c___`に渡す配列の最初の要素に入れたProcオブジェクトは`Sisimai::Message->parse()`で呼び出されます。

```ruby
#! /usr/bin/env ruby
require 'sisimai'
code = lambda do |args|
  head = args['headers']    # (*Hash)  メールヘッダー
  body = args['message']    # (String) メールの本文
  adds = { 'x-mailer' => '', 'queue-id' => '' }

  if cv = body.match(/^X-Postfix-Queue-ID:\s*(.+)$/)
    adds['queue-id'] = cv[1]
  end
  r['x-mailer'] = head['x-mailer'] || ''
  return adds
end

data = Sisimai.rise('/path/to/mbox', c___: [code, nil])
json = Sisimai.dump('/path/to/mbox', c___: [code, nil])

puts data[0].catch['x-mailer']  # "Apple Mail (2.1283)"
puts data[0].catch['queue-id']  # "43f4KX6WR7z1xcMG"
```

### 各メールのファイルに対して
`Sisimai.rise`と`Sisimai.dump`の両メソッドに渡せる引数`:c___`(配列)の2番目に入れた`Proc`オブジェクト
は解析したメールのファイルごとに呼び出されます。

```ruby
path = '/path/to/maildir'
code = lambda do |args|
  kind = args['kind']   # (String) Sisimai::Mail.kind
  mail = args['mail']   # (String) Entire email message
  path = args['path']   # (String) Sisimai::Mail.path
  fact = args['fact']   # (Array)  List of Sisimai::Fact

  fact.each do |e|
    # "catch"アクセサの中に独自の情報を保存する
    e.catch ||= {}
    e.catch['size'] = mail.size
    e.catch['kind'] = kind.capitalize

    if cv = mail.match(/^Return-Path: (.+)$/)
      # Return-Path: <MAILER-DAEMON>
      e.catch['return-path'] = cv[1]
    end
    e.catch['parsedat'] = Time.new.localtime.to_s

    # "X-Sisimai-Parsed:"ヘッダーを追加して別のPATHに元メールを保存する
    a = sprintf("X-Sisimai-Parsed: %d", fact.size)
    p = sprintf("/path/to/another/directory/sisimai-%s.eml", e.token)
    v = mail.sub(/^(From:.+?)$/, '\1' + "\n" + a)
    f = File.open(p, 'w:UTF-8')
    f.write(v)
    f.close

    # 解析が終わったらMaildir/にあるファイルを削除する
    File.delete(path) if kind == 'maildir'

    # 特に何か値をReturnする必要はない
  end
end

list = Sisimai.rise(path, c___: [nil, code])

puts list[0].catch['size']          # 2202
puts list[0].catch['kind']          # "Maildir"
puts list[0].catch['return-path']   # "<MAILER-DAEMON>"
```

コールバック機能のより詳細な使い方は
[Sisimai | 解析方法 - コールバック機能](https://libsisimai.org/ja/usage/#callback)をご覧ください。

One-Liner
---------------------------------------------------------------------------------------------------
```shell
$ ruby -rsisimai -e 'puts Sisimai.dump($*.shift)' /path/to/mbox
```

Output example
---------------------------------------------------------------------------------------------------
![](https://libsisimai.org/static/images/demo/sisimai-5-cli-dump-r01.gif)

```json
[
  {
    "destination": "google.example.com",
    "lhost": "gmail-smtp-in.l.google.com",
    "hardbounce": 0,
    "reason": "authfailure",
    "catch": null,
    "addresser": "michitsuna@example.jp",
    "alias": "nekochan@example.co.jp",
    "smtpagent": "Postfix",
    "smtpcommand": "DATA",
    "senderdomain": "example.jp",
    "listid": "",
    "action": "failed",
    "feedbacktype": "",
    "messageid": "hwK7pzjzJtz0RF9Y@relay3.example.com",
    "origin": "./gmail-5.7.26.eml",
    "recipient": "kijitora@google.example.com",
    "rhost": "gmail-smtp-in.l.google.com",
    "subject": "Nyaan",
    "timezoneoffset": "+0900",
    "replycode": 550,
    "token": "84656774898baa90660be3e12fe0526e108d4473",
    "diagnostictype": "SMTP",
    "timestamp": 1650119685,
    "diagnosticcode": "host gmail-smtp-in.l.google.com[64.233.187.27] said: This mail has been blocked because the sender is unauthenticated. Gmail requires all senders to authenticate with either SPF or DKIM. Authentication results: DKIM = did not pass SPF [relay3.example.com] with ip: [192.0.2.22] = did not pass For instructions on setting up authentication, go to https://support.google.com/mail/answer/81126#authentication c2-202200202020202020222222cat.127 - gsmtp (in reply to end of DATA command)",
    "deliverystatus": "5.7.26"
  }
]
```

Differences between Sisimai 4 and Sisimai 5
===================================================================================================
[Sisimai 4.25.16p1](https://github.com/sisimai/rb-sisimai/releases/tag/v4.25.16p1)と
[Sisimai 5](https://github.com/sisimai/rb-sisimai/releases/tag/v5.0.0)には下記のような違いがあります。
それぞれの詳細は[Sisimai | 違いの一覧](https://libsisimai.org/ja/diff/)を参照してください。

Features
---------------------------------------------------------------------------------------------------
Sisimai 5.0.0から**Ruby 2.4以上**が必要になります。

| 機能                                                 | Sisimai 4          | Sisimai 5           |
|------------------------------------------------------|--------------------|---------------------|
| 動作環境(CRuby)                                      | 2.1 -              | **2.4** - 3.3.0     |
| ~~動作環境(JRuby)                                    | 9.0.4.0 - 9.1.17.0 | 9.0.4.0 - 9.1.17.0  |~~
| 元メールファイルを操作可能なコールバック機能         | なし               | あり[^3]            |
| 解析エンジン(MTA/ESPモジュール)の数                  | 68                 | 70                  |
| 検出可能なバウンス理由の数                           | 29                 | 34                  |
| 依存Gem数(Ruby Standard Gemsを除く)                  | 1 Gem              | 1 Gem               |
| ソースコードの行数                                   | 10,800 行          | 11,400 行           |
| テストフレームワーク                                 | rspec              | minitest            |
| テスト件数(spec/またはtest/ディレクトリ)             | 311,000 件         | 336,000 件          |
| 1秒間に解析できるバウンスメール数[^4]                | 231 通             | 305 通              |
| ライセンス                                           | 2条項BSD           | 2条項BSD            |
| 開発会社による商用サポート                           | 提供中             | 提供中              |

[^3]: `Sisimai.rise`メソッドで指定する`:c___`パラメーター第二引数で指定可能
[^4]: macOS Monterey/1.6GHz Dual-Core Intel Core i5/16GB-RAM/Ruby 3.3.0

Decoding Method
---------------------------------------------------------------------------------------------------
いくつかの解析メソッド名、クラス名、パラメーター名がSisimai 5で変更になっています。解析済みデータの
各項目は[LIBSISIMAI.ORG/JA/DATA](https://libsisimai.org/ja/data/)を参照してください。

| 解析用メソッド周辺の変更箇所                         | Sisimai 4          | Sisimai 5           |
|------------------------------------------------------|--------------------|---------------------|
| 解析メソッド名                                       | `Sisimai.make`     | `Sisimai.rise`      |
| 出力メソッド名                                       | `Sisimai.dump`     | `Sisimai.dump`      |
| 解析メソッドが返すオブジェクトのクラス               | `Sisimai::Data`    | `Sisimai::Fact`     |
| コールバック用のパラメーター名                       | `hook`             | `c___`[^5]          |
| ハードバウンスかソフトバウンスかを識別するメソッド名 | `softbounce`       | `hardbounce`        |
| "vacation"をデフォルトで検出するかどうか             | 検出する           | 検出しない          |
| Sisimai::Messageがオブジェクトを返すかどうか         | 返す               | 返さない            |
| MIME解析用クラスの名前                               | `Sisimai::MIME`    | `Sisimai::RFC2045`  |
| SMTPセッションの解析をするかどうか                   | しない             | する[^6]            |

[^5]: `:c___`は漁港で使う釣り針に見える
[^6]: `Sisimai::SMTP::Transcript.rise`メソッドによる

MTA/ESP Module Names
---------------------------------------------------------------------------------------------------
Sisimai 5で3個のESPモジュール名(解析エンジン)が変更になりました。詳細はMTA/ESPモジュールの一覧/
[LIBSISIMAI.ORG/JA/ENGINE](https://libsisimai.org/ja/engine/)を参照してください。

| `Sisimai::Rhost::`                                   | Sisimai 4          | Sisimai 5           |
|------------------------------------------------------|--------------------|---------------------|
| Microsoft Exchange Online                            | `ExchangeOnline`   | `Microsoft`         |
| Google Workspace                                     | `GoogleApps`       | `Google`            |
| Tencent                                              | `TencentQQ`        | `Tencent`           |

Bounce Reasons
---------------------------------------------------------------------------------------------------
Sisimai 5では新たに5個のバウンス理由が増えました。検出可能なバウンス理由の一覧は
[LIBSISIMAI.ORG/JA/REASON](https://libsisimai.org/en/reason/)を参照してください。

| バウンスした理由                                     | Sisimai 4          | Sisimai 5           |
|------------------------------------------------------|--------------------|---------------------|
| ドメイン認証によるもの(SPF,DKIM,DMARC)               | `SecurityError`    | `AuthFailure`       |
| 送信者のドメイン・IPアドレスの低いレピュテーション   | `Blocked`          | `BadReputation`     |
| PTRレコードが未設定または無効なPTRレコード           | `Blocked`          | `RequirePTR`        |
| RFCに準拠していないメール[^7]                        | `SecurityError`    | `NotCompliantRFC`   |
| 単位時間の流量制限・送信速度が速すぎる               | `SecurityError`    | `Speeding`          |

[^7]: RFC5322など

Contributing
===================================================================================================
Bug report
---------------------------------------------------------------------------------------------------
もしもSisimaiにバグを発見した場合は[Issues](https://github.com/sisimai/rb-sisimai/issues)にて連絡を
いただけると助かります。

Emails could not be decoded
---------------------------------------------------------------------------------------------------
Sisimaiで解析できないバウンスメールは
[set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet](https://github.com/sisimai/set-of-emails/tree/master/to-be-debugged-because/sisimai-cannot-parse-yet)リポジトリに追加してPull-Requestを送ってください。

Other Information
===================================================================================================
Related sites
---------------------------------------------------------------------------------------------------
* __@libsisimai__ | [Sisimai on Twitter (@libsisimai)](https://twitter.com/libsisimai)
* __LIBSISIMAI.ORG__ | [SISIMAI | MAIL ANALYZING INTERFACE | DECODING BOUNCES, BETTER AND FASTER.](https://libsisimai.org/)
* __Sisimai Blog__ | [blog.libsisimai.org](http://blog.libsisimai.org/)
* __Facebook Page__ | [facebook.com/libsisimai](https://www.facebook.com/libsisimai/)
* __GitHub__ | [github.com/sisimai/rb-sisimai](https://github.com/sisimai/rb-sisimai)
* __RubyGems.org__ | [rubygems.org/gems/sisimai](https://rubygems.org/gems/sisimai)
* __Perl verson__ | [Perl version of Sisimai](https://github.com/sisimai/p5-sisimai)
* __Fixtures__ | [set-of-emails - Sample emails for "make test"](https://github.com/sisimai/set-of-emails)

See also
---------------------------------------------------------------------------------------------------
* [README.md - README.md in English](https://github.com/sisimai/rb-sisimai/blob/master/README.md)
* [RFC3463 - Enhanced Mail System Status Codes](https://tools.ietf.org/html/rfc3463)
* [RFC3464 - An Extensible Message Format for Delivery Status Notifications](https://tools.ietf.org/html/rfc3464)
* [RFC3834 - Recommendations for Automatic Responses to Electronic Mail](https://tools.ietf.org/html/rfc3834)
* [RFC5321 - Simple Mail Transfer Protocol](https://tools.ietf.org/html/rfc5321)
* [RFC5322 - Internet Message Format](https://tools.ietf.org/html/rfc5322)

Author
===================================================================================================
[@azumakuniyuki](https://twitter.com/azumakuniyuki)

Copyright
===================================================================================================
Copyright (C) 2015-2024 azumakuniyuki, All Rights Reserved.

License
===================================================================================================
This software is distributed under The BSD 2-Clause License.

