[![License](https://img.shields.io/badge/license-BSD%202--Clause-orange.svg)](https://github.com/sisimai/rb-Sisimai/blob/master/LICENSE)
[![Coverage Status](https://img.shields.io/coveralls/sisimai/rb-Sisimai.svg)](https://coveralls.io/r/sisimai/rb-Sisimai)
[![Build Status](https://travis-ci.org/sisimai/rb-Sisimai.svg?branch=master)](https://travis-ci.org/sisimai/rb-Sisimai) 
[![Codacy Badge](https://api.codacy.com/project/badge/grade/38340177e6284a65be69c0c7c3dc2b58)](https://www.codacy.com/app/azumakuniyuki/rb-Sisimai)
[![Ruby](https://img.shields.io/badge/ruby-v2.1.0--v2.3.0-red.svg)](https://www.ruby-lang.org/)
[![Gem Version](https://badge.fury.io/rb/sisimai.svg)](https://badge.fury.io/rb/sisimai)

![](http://41.media.tumblr.com/45c8d33bea2f92da707f4bbe66251d6b/tumblr_nuf7bgeyH51uz9e9oo1_1280.png)

What is Sisimai ?
=================
Sisimai is a Ruby library for analyzing RFC5322 bounce emails and generating
structured data from parsed results. The Ruby version of Sisimai is ported from
the Perl version of Sisimai at [github.com/sisimai/p5-Sisimai](https://github.com/sisimai/p5-Sisimai/).

Key Features
------------
* __Convert Bounce Mails to Structured Data__
  * Supported formats are Perl and JSON
* __Easy to Install, Use.__
  * gem install
  * git clone & make
* __High Precision of Analysis__
  * 2 times higher than bounceHammer
  * Support 22 known MTAs and 5 unknown MTAs
  * Support 21 major MSPs(Mail Service Providers)
  * Support Feedback Loop Message(ARF)
  * Can detect 27 error reasons

Setting Up Sisimai
==================
System requirements
-------------------
More details about system requirements are available at
[Sisimai | Getting Started](http://libsisimai.org/en/start) page.


* [Ruby 2.1.0 or later](http://www.ruby-lang.org/)
  * [__Oj | The fastest JSON parser and object serializer__](https://rubygems.org/gems/oj)
* Also works on [JRuby 9.0.0.0 or later](http://jruby.org)
  * [__JrJackson | A mostly native JRuby wrapper for the java jackson json processor jar__](https://rubygems.org/gems/jrjackson)

Install
----------------------
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

Usage
=====
Basic usage
-----------
`make()` method provides feature for getting parsed data from bounced email 
messages like following.

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

One-Liner
---------

```shell
% ruby -rsisimai -e 'puts Sisimai.dump($*.shift)' /path/to/mbox
```

Differences between Perl version and Ruby version
-------------------------------------------------
The following table show the differences between Perl version of Sisimai
and Ruby version of Sisimai. Information about differences between Sisimai
and bounceHammer are available at
[Sisimai | Differences](http://libsisimai.org/en/diff) page.

| Features                                    | Ruby version   | Perl version  |
|---------------------------------------------|----------------|---------------|
| System requirements                         | Ruby 2.1-2.3   | Perl 5.10 -   |
|                                             | JRuby 9.0.4.0- |               |
| Analytical precision ratio(2000 emails)[1]  | 1.00           | 1.00          |
| The speed of parsing email(1000 emails)     | 3.30s          | 2.33s         |
| How to install                              | gem install    | cpanm         |
| Dependencies (Except core modules)          | 1 modules      | 2 modules     |
| LOC:Source lines of code                    | 11500 lines    | 8400 lines    |
| The number of tests in t/, xt/ directory    | 95000 tests    | 172000 tests  |
| License                                     | BSD 2-Clause   | BSD 2-Clause  |
| Support Contract provided by Developer      | Coming soon    | Available     |

1. See [./ANALYTICAL-PRECISION](https://github.com/sisimai/rb-Sisimai/blob/master/ANALYTICAL-PRECISION)

MTA/MSP Modules
---------------
The following table is the list of MTA/MSP:(Mail Service Provider) modules. More
details about these modules are available at 
[Sisimai | Parser Engines](http://libsisimai.org/en/engine) page.

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

Bounce Reason List
------------------
Sisimai can detect the following 27 bounce reasons. More details about reasons
are available at [Sisimai | Bounce Reason List](http://libsisimai.org/en/reason)
page.

| Reason         | Description                            | Impelmented at     |
|----------------|----------------------------------------|--------------------|
| Blocked        | Blocked due to client IP address       |                    |
| ContentError   | Invalid format email                   |                    |
| Delivered[1]   | Successfully delivered                 | v4.16.0            |
| ExceedLimit    | Message size exceeded the limit(5.2.3) |                    |
| Expired        | Delivery time expired                  |                    |
| Feedback       | Bounced for a complaint of the message |                    |
| Filtered       | Rejected after DATA command            |                    |
| HasMoved       | Destination mail addrees has moved     |                    |
| HostUnknown    | Unknown destination host name          |                    |
| MailboxFull    | Recipient's mailbox is full            |                    |
| MailerError    | Mailer program error                   |                    |
| MesgTooBig     | Message size is too big(5.3.4)         |                    |
| NetworkError   | Network error: DNS or routing          |                    |
| NotAccept      | Destinaion does not accept any message |                    |
| OnHold         | Deciding the bounce reason is on hold  |                    |
| Rejected       | Rejected due to envelope from address  |                    |
| NoRelaying     | Relay access denied                    |                    |
| SecurityError  | Virus detected or authentication error |                    |
| SpamDetected   | Detected a message as spam             |                    |
| Suspend        | Recipient's account is suspended       |                    |
| SyntaxError    | syntax error in SMTP                   | v4.17.0            |
| SystemError    | Some error on the destination host     |                    |
| SystemFull     | Disk full on the destination host      |                    |
| TooManyConn    | Connection rate limit exceeded         |                    |
| UserUnknown    | Recipient's address does not exist     |                    |
| Undefined      | Could not decide the error reason      |                    |
| Vacation       | Auto replied message                   | v4.1.28            |

1. This reason is not included by default

Parsed data structure
---------------------
The following table shows a data structure(`Sisimai::Data`) of parsed bounce mail.
More details about data structure are available at available at 
[Sisimai | Data Structure of Sisimai::Data](http://libsisimai.org/en/data) page.

| Name           | Description                                                 |
|----------------|-------------------------------------------------------------|
| action         | The value of Action: header                                 |
| addresser      | The sender's email address (From:)                          |
| alias          | Alias of the recipient                                      |
| destination    | The domain part of the "recipinet"                          |
| deliverystatus | Delivery Status(DSN), ex) 5.1.1, 4.4.7                      |
| diagnosticcode | Error message                                               |
| diagnostictype | Error message type                                          |
| feedbacktype   | Feedback Type                                               |
| lhost          | local host name(local MTA)                                  |
| listid         | The value of List-Id: header of the original message        |
| messageid      | The value of Message-Id: of the original message            |
| reason         | Detected bounce reason                                      |
| recipient      | Recipient address which bounced (To:)                       |
| replycode      | SMTP Reply Code, ex) 550, 421                               |
| rhost          | Remote host name(remote MTA)                                |
| senderdomain   | The domain part of the "addresser"                          |
| softbounce     | The bounce is soft bounce or not: 0=hard,1=soft,-1=unknown  |
| smtpagent      | MTA module name (Sisimai::MTA::, MSP::)                     |
| smtpcommand    | The last SMTP command in the session                        |
| subject        | The vale of Subject: header of the original message(UTF8)   |
| timestamp      | Timestamp of the bounce, UNIX matchine time                 |
| timezoneoffset | Time zone offset string: ex) +0900                          |
| token          | MD5 value of addresser, recipient, and the timestamp        |

Emails could not be parsed
--------------------------
Bounce mails which could not be parsed by Sisimai are saved in the directory
`set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet`. If you have
found any bounce email cannot be parsed using Sisimai, please add the email
into the directory and send Pull-Request to this repository.

Other Information
=================
Related Sites
-------------
* __@libsisimai__ | [Sisimai on Twitter (@libsisimai)](https://twitter.com/libsisimai)
* __libsisimai.org__ | [Sisimai | The successor to bounceHammer, Library to parse bounce mails](http://libsisimai.org/)
* __GitHub__ | [github.com/sisimai/rb-Sisimai](https://github.com/sisimai/rb-Sisimai)
* __Perl verson__ | [Perl version of Sisimai](https://github.com/sisimai/p5-Sisimai)

SEE ALSO
--------
* [README-JA.md - README.md in Japanese(日本語)](https://github.com/sisimai/rb-Sisimai/blob/master/README-JA.md)
* [RFC3463 - Enhanced Mail System Status Codes](https://tools.ietf.org/html/rfc3463)
* [RFC3464 - An Extensible Message Format for Delivery Status Notifications](https://tools.ietf.org/html/rfc3464)
* [RFC3834 - Recommendations for Automatic Responses to Electronic Mail](https://tools.ietf.org/html/rfc3834)
* [RFC5321 - Simple Mail Transfer Protocol](https://tools.ietf.org/html/rfc5321)
* [RFC5322 - Internet Message Format](https://tools.ietf.org/html/rfc5322)

AUTHOR
------
[@azumakuniyuki](https://twitter.com/azumakuniyuki)

COPYRIGHT
---------
Copyright (C) 2015-2016 azumakuniyuki, All Rights Reserved.

LICENSE
-------
This software is distributed under The BSD 2-Clause License.

