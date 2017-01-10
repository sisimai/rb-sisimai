![](http://libsisimai.org/static/images/logo/sisimai-x01.png)

[![License](https://img.shields.io/badge/license-BSD%202--Clause-orange.svg)](https://github.com/sisimai/rb-Sisimai/blob/master/LICENSE)
[![Coverage Status](https://img.shields.io/coveralls/sisimai/rb-Sisimai.svg)](https://coveralls.io/r/sisimai/rb-Sisimai)
[![Build Status](https://travis-ci.org/sisimai/rb-Sisimai.svg?branch=master)](https://travis-ci.org/sisimai/rb-Sisimai) 
[![Codacy Badge](https://api.codacy.com/project/badge/grade/38340177e6284a65be69c0c7c3dc2b58)](https://www.codacy.com/app/azumakuniyuki/rb-Sisimai)
[![Ruby](https://img.shields.io/badge/ruby-v2.1.0--v2.4.0-red.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/sisimai.svg)](https://badge.fury.io/rb/sisimai)

- [**README-JA(日本語)**](README-JA.md)
- [What is Sisimai](#what-is-sisimai)
    - [Key features](#key-features)
    - [Command line demo](#command-line-demo)
- [Setting Up Sisimai](#setting-up-sisimai)
    - [System requirements](#system-requirements)
    - [Install](#install)
        - [From RubyGems](#from-rubygems)
        - [From GitHub](#from-github)
- [Usage](#usage)
    - [Basic usage](#basic-usage)
    - [Convert to JSON](#convert-to-json)
    - [Read bounce object](#read-bounce-object)
    - [Callback feature](#callback-feature)
    - [One-Liner](#one-liner)
    - [Output example](#output-example)
- [Sisimai Specification](#sisimai-specification)
    - [Differences between Ruby version and Perl version](#differences-between-ruby-version-and-perl-version)
    - [Other specification of Sisimai](#other-specification-of-sisimai)
- [Contributing](#contributing)
    - [Bug report](#bug-report)
    - [Emails could not be parsed](#emails-could-not-be-parsed)
- [Other Information](#other-information)
    - [Related sites](#related-sites)
    - [See also](#see-also)
- [Author](#author)
- [Copyright](#copyright)
- [License](#license)

What is Sisimai
===============================================================================
Sisimai is a Ruby library for analyzing RFC5322 bounce emails and generating
structured data from parsed results. The Ruby version of Sisimai is ported from
the Perl version of Sisimai at [github.com/sisimai/p5-Sisimai](https://github.com/sisimai/p5-Sisimai/).

Key Features
-------------------------------------------------------------------------------
* __Convert Bounce Mails to Structured Data__
  * Supported formats are Ruby(Hash, Array) and JSON(String)
* __Easy to Install, Use.__
  * gem install
  * git clone & make
* __High Precision of Analysis__
  * 2 times higher than bounceHammer
  * Support 22 known MTAs and 5 unknown MTAs
  * Support 21 major MSPs(Mail Service Providers)
  * Support 2 major Cloud Email Delivery Services(JSON format)
  * Support Feedback Loop Message(ARF)
  * Can detect 27 error reasons

Command line demo
-------------------------------------------------------------------------------
The following screen shows a demonstration of Sisimai at the command line using
Ruby(rb-Sisimai) and Perl(p5-Sisimai) version of Sisimai.
![](http://libsisimai.org/static/images/demo/sisimai-dump-01.gif)

Setting Up Sisimai
===============================================================================

System requirements
-------------------------------------------------------------------------------
More details about system requirements are available at
[Sisimai | Getting Started](http://libsisimai.org/en/start) page.


* [Ruby 2.1.0 or later](http://www.ruby-lang.org/)
  * [__Oj | The fastest JSON parser and object serializer__](https://rubygems.org/gems/oj)
* Also works on [JRuby 9.0.4.0 or later](http://jruby.org)
  * [__JrJackson | A mostly native JRuby wrapper for the java jackson json processor jar__](https://rubygems.org/gems/jrjackson)

Install
-------------------------------------------------------------------------------
### From RubyGems

```shell
$ sudo gem install sisimai
Fetching: sisimai-4.20.0.gem (100%)
Successfully installed sisimai-4.20.0
Parsing documentation for sisimai-4.20.0
Installing ri documentation for sisimai-4.20.0
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
sisimai 4.20.0 built to pkg/sisimai-4.20.0.gem.
sisimai (4.20.0) installed.
```

Usage
===============================================================================

Basic usage
-------------------------------------------------------------------------------
`make()` method provides feature for getting parsed data from bounced email 
messages like following.

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
`Sisimai.dump()` method provides feature for getting parsed data as JSON string
from bounced email messages like following.

```ruby
# Get JSON string from parsed mailbox or Maildir/
puts Sisimai.dump('/path/to/mbox')  # or path to Maildir/

# dump() method also accepts "delivered" option like the following code:
puts Sisimai.dump('/path/to/mbox', delivered: true)
```

Read bounce object
-------------------------------------------------------------------------------
The way to read a bounce object retrived from Cloud Email Services as JSON using
their API is the following code. This feature is available at Sisimai 4.20.0 or
later.

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
As of present, Only Amazon SES and SendGrid are supported.

Callback feature
-------------------------------------------------------------------------------
Beginning with Sisimai 4.19.0, `make()` and `dump()` methods of Sisimai accept
a Lambda (Proc object) in `hook` argument for setting a callback method and
getting the results generated by the method via `Sisimai::Data.catch` method.

```ruby
#! /usr/bin/env ruby
require 'sisimai'
callbackto = lambda do |v|
  r = { 'x-mailer' => '' }

  if cv = v['message'].match(/^X-Mailer:\s*(.+)$/)
    r['x-mailer'] = cv[1]
  end
  return r
end

data = Sisimai.make('/path/to/mbox', hook: callbackto)
json = Sisimai.dump('/path/to/mbox', hook: callbackto)

puts data[0].catch['x-mailer']      # Apple Mail (2.1283)
```

More information about the callback feature is available at
[Sisimai | How To Parse - Callback](http://libsisimai.org/en/usage/#callback)
Page.

One-Liner
-------------------------------------------------------------------------------

```shell
% ruby -rsisimai -e 'puts Sisimai.dump($*.shift)' /path/to/mbox
```

Output example
-------------------------------------------------------------------------------
```json
[{"recipient": "kijitora@example.jp", "addresser": "shironeko@1jo.example.org", "feedbacktype": "", "action": "failed", "subject": "Nyaaaaan", "smtpcommand": "DATA", "diagnosticcode": "550 Unknown user kijitora@example.jp", "listid": "", "destination": "example.jp", "smtpagent": "Courier", "lhost": "1jo.example.org", "deliverystatus": "5.0.0", "timestamp": 1291954879, "messageid": "201012100421.oBA4LJFU042012@1jo.example.org", "diagnostictype": "SMTP", "timezoneoffset": "+0900", "reason": "filtered", "token": "ce999a4c869e3f5e4d8a77b2e310b23960fb32ab", "alias": "", "senderdomain": "1jo.example.org", "rhost": "mfsmax.example.jp"}, {"diagnostictype": "SMTP", "timezoneoffset": "+0900", "reason": "userunknown", "timestamp": 1381900535, "messageid": "E1C50F1B-1C83-4820-BC36-AC6FBFBE8568@example.org", "token": "9fe754876e9133aae5d20f0fd8dd7f05b4e9d9f0", "alias": "", "senderdomain": "example.org", "rhost": "mx.bouncehammer.jp", "action": "failed", "addresser": "kijitora@example.org", "recipient": "userunknown@bouncehammer.jp", "feedbacktype": "", "smtpcommand": "DATA", "subject": "バウンスメールのテスト(日本語)", "destination": "bouncehammer.jp", "listid": "", "diagnosticcode": "550 5.1.1 <userunknown@bouncehammer.jp>... User Unknown", "deliverystatus": "5.1.1", "lhost": "p0000-ipbfpfx00kyoto.kyoto.example.co.jp", "smtpagent": "Sendmail"}]
```

Sisimai Specification
===============================================================================

Differences between Ruby version and Perl version
-------------------------------------------------------------------------------
The following table show the differences between Ruby version of Sisimai
and Perl version of Sisimai. Information about differences between Sisimai
and bounceHammer are available at
[Sisimai | Differences](http://libsisimai.org/en/diff) page.

| Features                                    | Ruby version   | Perl version  |
|---------------------------------------------|----------------|---------------|
| System requirements                         | Ruby 2.1 - 2.4 | Perl 5.10 -   |
|                                             | JRuby 9.0.4.0- |               |
| Analytical precision ratio(2000 emails)[1]  | 1.00           | 1.00          |
| The speed of parsing email(1000 emails)     | 3.30s          | 2.33s         |
| How to install                              | gem install    | cpanm         |
| Dependencies (Except core modules)          | 1 module       | 2 modules     |
| LOC:Source lines of code                    | 12200 lines    | 8800 lines    |
| The number of tests(spec/,t/,xt/) directory | 106400 tests   | 188000 tests  |
| License                                     | BSD 2-Clause   | BSD 2-Clause  |
| Support Contract provided by Developer      | Coming soon    | Available     |

1. See [./ANALYTICAL-PRECISION](https://github.com/sisimai/rb-Sisimai/blob/master/ANALYTICAL-PRECISION)

Other specification of Sisimai
-------------------------------------------------------------------------------
- [**Parser Engines**](http://libsisimai.org/en/engine)
- [**Bounce Reason List**](http://libsisimai.org/en/reason)
- [**Data Structure of Sisimai::Data**](http://libsisimai.org/en/data)

Contributing
===============================================================================

Bug report
-------------------------------------------------------------------------------
Please use the [issue tracker](https://github.com/sisimai/rb-Sisimai/issues)
to report any bugs.

Emails could not be parsed
-------------------------------------------------------------------------------
Bounce mails which could not be parsed by Sisimai are saved in the repository
[set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet](https://github.com/sisimai/set-of-emails/tree/master/to-be-debugged-because/sisimai-cannot-parse-yet). 
If you have found any bounce email cannot be parsed using Sisimai, please add
the email into the directory and send Pull-Request to this repository.

Other Information
===============================================================================

Related Sites
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
* [README-JA.md - README.md in Japanese(日本語)](https://github.com/sisimai/rb-Sisimai/blob/master/README-JA.md)
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

