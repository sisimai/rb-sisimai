![](https://libsisimai.org/static/images/logo/sisimai-x01.png)

[![License](https://img.shields.io/badge/license-BSD%202--Clause-orange.svg)](https://github.com/sisimai/rb-sisimai/blob/master/LICENSE)
[![Coverage Status](https://img.shields.io/coveralls/sisimai/rb-sisimai.svg)](https://coveralls.io/r/sisimai/rb-sisimai)
[![Ruby](https://img.shields.io/badge/ruby-v2.1.0--v3.3.0-red.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/sisimai.svg)](https://badge.fury.io/rb/sisimai)

> [!IMPORTANT]
> **The default branch of this repository is [5-stable](https://github.com/sisimai/rb-sisimai/tree/5-stable)
> (Sisimai 5) since 2nd February 2024.**
> If you want to clone the old version, see the [4-stable](https://github.com/sisimai/rb-sisimai/tree/4-stable)
> branch instead. We have moved away from using both the `main` and `master` branches in our development process.

> [!CAUTION]
> **Sisimai versions 4.25.14p11 and earlier contain a regular expression vulnerability 
> [ReDoS: CVE-2022-4891](https://nvd.nist.gov/vuln/detail/CVE-2022-4891).
> If you are using one of these versions, please upgrade to v4.25.14p12 or later.**

> [!WARNING]
> Sisimai 5 requires Ruby 2.4 or later. Check the version of Ruby in your system before installing/upgrading
> by `ruby -v` command.

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
the Perl version of Sisimai at [github.com/sisimai/p5-sisimai](https://github.com/sisimai/p5-sisimai/).

![](https://libsisimai.org/static/images/figure/sisimai-overview-1.png)

Key Features
-------------------------------------------------------------------------------
* __Convert Bounce Mails to Structured Data__
  * Supported formats are Ruby(Hash, Array) and JSON(String)
* __Easy to Install, Use.__
  * gem install
  * git clone & make
* __High Precision of Analysis__
  * 2 times higher than bounceHammer
  * Support 68 MTAs/MDAs/ESPs
  * Support Feedback Loop Message(ARF)
  * Can detect 29 error reasons

Command line demo
-------------------------------------------------------------------------------
The following screen shows a demonstration of Sisimai at the command line using
Ruby(rb-sisimai) and Perl(p5-sisimai) version of Sisimai.
![](https://libsisimai.org/static/images/demo/sisimai-dump-01.gif)

Setting Up Sisimai
===============================================================================

System requirements
-------------------------------------------------------------------------------
More details about system requirements are available at
[Sisimai | Getting Started](https://libsisimai.org/en/start/) page.


* [Ruby 2.1.0 or later](http://www.ruby-lang.org/)
  * [__Oj | The fastest JSON parser and object serializer__](https://rubygems.org/gems/oj)
* Also works on [JRuby 9.0.4.0 - 9.1.17.0](http://jruby.org)
  * [__JrJackson | A mostly native JRuby wrapper for the java jackson json processor jar__](https://rubygems.org/gems/jrjackson)

Install
-------------------------------------------------------------------------------
### From RubyGems

```shell
$ sudo gem install sisimai
Fetching: sisimai-4.25.16.gem (100%)
Successfully installed sisimai-4.25.16
Parsing documentation for sisimai-4.25.16
Installing ri documentation for sisimai-4.25.16
Done installing documentation for sisimai after 6 seconds
1 gem installed
```

### From GitHub

```shell
$ cd /usr/local/src
$ git clone https://github.com/sisimai/rb-sisimai.git
$ cd ./rb-sisimai
$ sudo make depend install-from-local
gem install bundle rake rspec coveralls
...
4 gems installed
bundle exec rake install
sisimai 4.25.16 built to pkg/sisimai-4.25.16.gem.
sisimai (4.25.16) installed.
```

Usage
===============================================================================

Basic usage
-------------------------------------------------------------------------------
`make()` method provides feature for getting parsed data from bounced email 
messages like following. Beginning with v4.25.6, new accessor `origin` which
keeps the path to email file as a data source is available.


```ruby
#! /usr/bin/env ruby
require 'sisimai'
v = Sisimai.make('/path/to/mbox')       # or path to Maildir/

# Beginning with v4.23.0, both make() and dump() method of Sisimai class can
# read bounce messages from variable instead of a path to mailbox
f = File.open('/path/to/mbox', 'r');    # or path to Maildir/
v = Sisimai.make(f.read)

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
    puts e.origin               # /var/spool/bounce/Maildir/new/1740074341.eml

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

Callback feature
-------------------------------------------------------------------------------
Beginning with Sisimai 4.19.0, `make()` and `dump()` methods of Sisimai accept
a Lambda (Proc object) in `hook` argument for setting a callback method and
getting the results generated by the method via `Sisimai::Data.catch` method.

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

data = Sisimai.make('/path/to/mbox', hook: callbackto)
json = Sisimai.dump('/path/to/mbox', hook: callbackto)

puts data[0].catch['x-mailer']      # Apple Mail (2.1283)
```

More information about the callback feature is available at
[Sisimai | How To Parse - Callback](https://libsisimai.org/en/usage/#callback)
Page.

One-Liner
-------------------------------------------------------------------------------

```shell
% ruby -rsisimai -e 'puts Sisimai.dump($*.shift)' /path/to/mbox
```

Output example
-------------------------------------------------------------------------------
![](https://libsisimai.org/static/images/demo/sisimai-dump-02.gif)

```json
[{"catch":{"x-mailer":"","return-path":"<shironeko@mx.example.co.jp>"},"token":"cf17945938502bd876603a375f0e9517c921bbab","lhost":"localhost","rhost":"mx-s.neko.example.jp","alias":"","listid":"","reason":"hasmoved","action":"failed","origin":"set-of-emails/maildir/bsd/lhost-sendmail-22.eml","subject":"Nyaaaan","messageid":"0000000011111.fff0000000003@mx.example.co.jp","replycode":"","smtpagent":"Sendmail","softbounce":0,"smtpcommand":"DATA","destination":"example.net","senderdomain":"example.co.jp","feedbacktype":"","diagnosticcode":"450 busy - please try later 551 not our customer 503 need RCPT command [data]","diagnostictype":"SMTP","deliverystatus":"5.1.6","timezoneoffset":"+0900","addresser":"shironeko@example.co.jp","recipient":"kijitora@example.net","timestamp":1397054085}]
```

Sisimai Specification
===============================================================================

Differences between Ruby version and Perl version
-------------------------------------------------------------------------------
The following table show the differences between Ruby version of Sisimai
and Perl version of Sisimai. Information about differences between Sisimai
and bounceHammer are available at
[Sisimai | Differences](https://libsisimai.org/en/diff/) page.

| Features                                    | Ruby version   | Perl version  |
|---------------------------------------------|----------------|---------------|
| System requirements                         | Ruby 2.1 - 3.3 | Perl 5.10 -   |
|                                             | JRuby 9.0.4.0  |               |
|                                             | - 9.1.17.0     |               |
| Analytical precision ratio(2000 emails)[1]  | 1.00           | 1.00          |
| The speed of parsing email(1000 emails)     | 2.22s[2]       | 1.35s         |
| How to install                              | gem install    | cpanm, cpm    |
| Dependencies (Except core modules)          | 1 module       | 2 modules     |
| LOC:Source lines of code                    | 10600 lines    | 10800 lines   |
| The number of tests(spec/,t/,xt/) directory | 241000 tests   | 270000 tests  |
| License                                     | BSD 2-Clause   | BSD 2-Clause  |
| Support Contract provided by Developer      | Available      | Available     |

1. See [./ANALYTICAL-PRECISION](https://github.com/sisimai/rb-sisimai/blob/master/ANALYTICAL-PRECISION)
2. Xeon E5-2640 2.5GHz x 2 cores | 5000 bogomips | 1GB RAM | Ruby 2.3.4p301

Other specification of Sisimai
-------------------------------------------------------------------------------
- [**Parser Engines**](https://libsisimai.org/en/engine/)
- [**Bounce Reason List**](https://libsisimai.org/en/reason/)
- [**Data Structure of Sisimai::Data**](https://libsisimai.org/en/data/)

Contributing
===============================================================================

Bug report
-------------------------------------------------------------------------------
Please use the [issue tracker](https://github.com/sisimai/rb-sisimai/issues)
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
* __LIBSISIMAI.ORG__ | [SISIMAI | MAIL ANALYZING INTERFACE | DECODING BOUNCES, BETTER AND FASTER.](https://libsisimai.org/)
* __Sisimai Blog__ | [blog.libsisimai.org](http://blog.libsisimai.org/)
* __Facebook Page__ | [facebook.com/libsisimai](https://www.facebook.com/libsisimai/)
* __GitHub__ | [github.com/sisimai/rb-sisimai](https://github.com/sisimai/rb-sisimai)
* __RubyGems.org__ | [rubygems.org/gems/sisimai](https://rubygems.org/gems/sisimai)
* __Perl verson__ | [Perl version of Sisimai](https://github.com/sisimai/p5-sisimai)
* __Fixtures__ | [set-of-emails - Sample emails for "make test"](https://github.com/sisimai/set-of-emails)

See also
-------------------------------------------------------------------------------
* [README-JA.md - README.md in Japanese(日本語)](https://github.com/sisimai/rb-sisimai/blob/master/README-JA.md)
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
Copyright (C) 2015-2024 azumakuniyuki, All Rights Reserved.

License
===============================================================================
This software is distributed under The BSD 2-Clause License.

