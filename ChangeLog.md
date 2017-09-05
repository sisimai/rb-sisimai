RELEASE NOTES for Ruby version of Sisimai
================================================================================
- releases: "https://github.com/sisimai/rb-Sisimai/releases"
- download: "https://rubygems.org/gems/sisimai"

v4.22.1p1
--------------------------------------------------------------------------------
- release: "Not released yet"
- version: ""
- changes:
  - Apply Pull-Request #84 (issue #83) for setting the value of `softorhard` in 
    `Sisimai::SMTP::Error.soft_or_hard` method. Thanks to @lunatyq.
  - Fix a wrong value assingment, and code for Performance/StartWith reported
    from Rubocop in Sisimai::Bite::Email::GSuite.
  - Update codes about Lint/AssignmentInCondition, Style/Next, Style/EmptyElse,
    Style/UselessAssignment, and others reported from Rubocop.
  - Fix code for Performance/Casecmp, Performance/LstripRstrip in Sisimai::MIME.
  - Update code for Style/SymbolProc in Sisimai::Message::Email.
  

v4.22.1
--------------------------------------------------------------------------------
- release: "Tue, 29 Aug 2017 17:25:22 +0900 (JST)"
- version: "4.22.1"
- changes:
  - Sisimai::Address was born again: import Pull-Request sisimai/p5-Sisimai#231
    - Implement new email address parser method: find()
    - Implement new constructor: make()
    - Implement new writable accessors: name() and comment()
    - parse() method was marked as obsoleted
  - **Require Oj 3.0.0 or later. Build test fails when the version of installed
    Oj is 2.18.* on CRuby.**
  - Tested on JRuby 9.1.9.0.
  - Fix wrong constant name in Sisimai::Rhost::ExchangeOnline reported at issue
    #77. Thanks to @rdeavila.
  - Improved code in Sisimai::Message::Email to avoid an exception reported at
    issue #82. Thanks to @hiroyuki-sato.
  - Fixed wrong bitwise operation in Sisimai::RFC3464 for getting the original
    message part Thanks to @hiroyuki-sato.

v4.22.0
--------------------------------------------------------------------------------
- release: "Tue, 22 Aug 2017 18:25:55 +0900 (JST)"
- version: "4.22.0"
- changes:
  - Import Pull-Request sisimai/p5-Sisimai#225, bounce reason: "securityerror"
    has been divided into the following three reasons:
    - securityerror
    - virusdetected
    - policyviolation
  - Issue #78 All the MTA modules have been moved to Sisimai::Bite::* and old
    MTA modules: Sisimai::MTA, Sisimai::MSP, Sisimai::CED, and all the methods
    in these classes have been marked as obsoleted.
  - Import Pull-Request sisimai/p5-Sisimai#230 Sisimai::Address.find method has
    been implemented experimentaly as bourne again parser for email addresses.

v4.21.1
--------------------------------------------------------------------------------
- release: "Mon, 29 May 2017 14:22:22 +0900 (JST)"
- version: "4.21.1"
- changes:
  - Pull-Request #73, Fix codes for initializing a hash element with an empty
    string in Sisimai::MTA::Postfix. Thanks to @MichiakiNakaya.
  - Import pull-request: https://github.com/sisimai/p5-Sisimai/pull/222 from
    p5-Sisimai to improve error message patterns.
  - Changes file has been renamed to **ChangeLog.md** and converted to Markdown
    format.
  - Import Pull-Request https://github.com/sisimai/p5-Sisimai/pull/223 for code
    improvement to detect DNS related errors at G Suite.
  - Improved code to detect RFC7505 (NullMX) error: sisimai/set-of-emails#4.
  - Code improvements for checking and decoding irregular MIME encoded strings
    at is_mimeencoded and mimedecode methods in Sisimai::MIME class reported at
    issue #75. Thanks to @winebarrel.
  - Add unit test codes to test all the changes at issue #75.

v4.21.0 - Support G Suite
--------------------------------------------------------------------------------
- release: "Mon, 10 Apr 2017 12:17:22 +0900 (JST)"
- version: "4.21.0"
- changes:
  - Experimental implementation: new MTA module Sisimai::MSP::US::GSuite for
    parsing a bounce mail returned from G Suite.
  - `Sisimai.make()` and `Sisimai::Message.new()` methods check the value of a
    `field` argument more strictly.
  - Improved `Sisimai::SMTP::Status.find()`. The method checks whether a found
    value as D.S.N. is IPv4 address or not.
  - Improved code for getting error messages, D.S.N. values, and SMTP reply
    codes in `Sisimai::MTA::Postfix.scan()` method.
  - Pull-Request #69, Fix some typos. Thanks to @koic.
  - Pull-Request #71, Fix break statement. Thanks to @MichiakiNakaya.
  - Issue #70, All the value of `$PATH` in Makefile have been fixed to build a
    gem file for JRuby Platform. Thanks to @MichiakiNakaya, @hiroyuki-sato.

v4.20.2
--------------------------------------------------------------------------------
- release: "Sat, 11 Mar 2017 16:32:48 +0900 (JST)"
- version: "4.20.2"
- changes:
  - Pull-Request #63 Add some error message patterns for a bounce message from
    Amazon SES SMTP endpoint.
  - Fix regular expression in `Sisimai::Message::Email.headers()` method for
    resolving issue #65 reported from @rdeavila.
  - Issue #67, Fix code in `Sisimai.make()` method for reading bounce email data
    from STDIN. Thanks to @marine_dayo.
  - Callback feature improvement: import pull-request from sisimai/p5-Sisimai
    https://github.com/sisimai/p5-Sisimai/pull/210.

v4.20.1
--------------------------------------------------------------------------------
- release: "Sat, 31 Dec 2016 20:10:22 +0900 (JST)"
- version: "4.20.1"
- changes:
  - Fix the Java version of Gem file.

v4.20.0 - Support Bounce Ojbect (JSON)
--------------------------------------------------------------------------------
- release: "Sat, 31 Dec 2016 13:36:22 +0900 (JST)"
- version: "4.20.0"
- changes:
  - Experimental implementation: New MTA modules for 2 Cloud Email Deliveries.
    These modules can parse JSON formatted bounce objects and can convert to
    Sisimai::Data object.
    - Sisimai::CED::US::AmazonSES
    - Sisimai::CED::US::SendGrid
  - Format of `smtpagent` in the parsed result has been changed. It includes the
    category name of MTA/MSP modules like `MTA::Sendmail`, `MTA::Postfix`, and
    `MSP::US::SendGrid`.
  - The Domain part of dummy email address defined in Sisimai::Address module
    has been changed from `dummy-domain.invalid` to `libsisimai.org.invalid`.
  - `Sisimai::SMTP.is_softbounce()` method has been deleted.
  - Code improvement for avoid `Invalid byte sequence in UTF-8 (ArgumentError)`
    error in `Sisimai::String.to_plain()` method reported from M.R.
  - Sisimai works on Ruby 2.4.0.

v4.19.0 - Callback Feature
--------------------------------------------------------------------------------
- release: "Tue, 18 Oct 2016 14:19:10 +0900 (JST)"
- version: "4.19.0"
- changes:
  - Implement a callback feature at `Sisimai.make()` and `Sisimai.dump()` methods.
    More imformation about the feature are available at the following pages:
    - http://libsisimai.org/en/usage#callback
    - http://libsisimai.org/ja/usage#callback
  - Implement `Sisimai.match()` method: issue #52.
  - Minor bug fix in `Sisimai::MSP::US::AmazonSES.scan()` method.

v4.18.1
--------------------------------------------------------------------------------
- release: "Sun, 11 Sep 2016 20:05:20 +0900 (JST)"
- version: "4.18.1"
- changes:
  - Fix bug in `Sisimai::Mail::STDIN.read()` method reported at issue #61.
    Thanks to @yaegassy.
  - Fix bug in `Sisimai::MIME.qprintd()` reported at issue #60.
  - Improved code related to MIME decoding.
  - Implement `Sisimai::String.to_plain()` for converting from HTML message to
    plain text before parsing. The method and related codes are imported from
    pull-request #197 at p5-Sisimai.

v4.18.0 - Improvements for Microsoft Exchange Servers
--------------------------------------------------------------------------------
- release: "Mon, 22 Aug 2016 20:40:55 +0900 (JST)"
- version: "4.18.0"
- changes:
  - Import pull-request https://github.com/sisimai/rb-Sisimai/pull/59 (soft
    bounce improvement) from Perl version of Sisimai.
  - Sisimai::MTA::Exchange has been renamed to Sisimai::MTA::Exchange2003.
  - Implement new MTA module Sisimai::MTA::Exchange2007.

v4.17.2
--------------------------------------------------------------------------------
- release: "Tue, 26 Jul 2016 21:00:17 +0900 (JST)"
- version: "4.17.2"
- changes:
  - Issue #174, Implement Sisimai::Rhost::ExchangeOnline for the bounce mail
    from on-premises Exchange 2013 and Office 365.
  - The reason of status code: `4.4.5` is `systemfull`.
  - Code improvement at Sisimai::MSP::US::Office365.

v4.17.1
--------------------------------------------------------------------------------
- release: "Wed, 30 Mar 2016 14:00:22 +0900 (JST)"
- version: "4.17.1"
- changes:
  - Ported codes from https://github.com/sisimai/p5-Sisimai/pull/180 for fixing
    issue https://github.com/sisimai/p5-Sisimai/issues/179,  a variable defined
    in `lib/sisimai/mta/exim.rb` is not quoted before passing to `%r//` operator.
  - Fixed serious bug in `Sisimai::Mail::Maildir#read` method reported at issue
    #55 and #56 by pull-request #57. Thanks to @taku1201.

v4.17.0 - New Error Reason "syntaxerror"
--------------------------------------------------------------------------------
- release: "Wed, 16 Mar 2016 12:22:44 +0900 (JST)"
- version: "4.17.0"
- changes:
  - Implement new reason **syntaxerror**. Sisimai will set `syntaxerror` to the
    raeson when the value of `replycode` begins with `50` such as 502, 503,
    or 504. Imported from https://github.com/sisimai/p5-Sisimai/pull/170.
  - Implement `description()` method at each class in `sisimai/reason/*.rb` and
    `Sisimai.reason()` method for getting the list of reasons Sisimai can detect
    and its description: issue #48.
  - Remove unused method `Sisimai::Reason.match()`, issue #49.
  - Some methods of Sisimai::Address class allow `postmaster`, `mailer-daemon`
    (without a domain part) as an email address.
  - `Sisimai::RFC5322.is_mailerdaemon()` method returns true when the argument
    includes `postmaster`.
  - Merge pull-request #51, new method `Sisimai::RFC5322.weedout()` and code
    improvements in all the MTA/MSP modules.


v4.16.0 - New Error Reason "delivered"
--------------------------------------------------------------------------------
- release: "Thu, 18 Feb 2016 13:49:01 +0900 (JST)"
- version: "4.16.0"
- changes:
  - Implement new reason **delivered**. Sisimai set `delivered` to the reason
    when the value of `Status:` field in a bounce message begins with `21. This
    feature is optional and is not enabled by default.
  - Implement new method `Sisimai.engine()`. The method returns the list of MTA
    and MSP module list implemented in Sisimai.
  - Fix serious bug (`gem install` fails on JRuby environment) in Gemfile and
    sisimai.gemspec. This bug is reported at issue #46 and pull-request #47.
    Thanks to @hiroyuki-sato and all the people who helped for resolving this
    issue on https://github.com/rubygems/rubygems/issues/1492.

v4.15.1
--------------------------------------------------------------------------------
- release: "Wed, 17 Feb 2016 01:36:45 +0900 (JST)"
- version: "4.15.1"
- changes:
  - Fix serious bug: command `gem install sisimai` fails on JRuby, reported at
    issue #46. Thanks to @hiroyuki-sato.
  - v4.15.1 exist on Ruby version of Sisimai only.

v4.15.0 - Oj or JrJackson Required
--------------------------------------------------------------------------------
- release: "Sat, 13 Feb 2016 12:40:15 +0900 (JST)"
- version: "4.15.0"
- changes:
  - Beginning with this version, Sisimai requires Oj(MRI) or JrJackson(JRuby)
    for encoding parsed data to JSON string more faster (about 10%-20% faster
    than before). Implemented at pull-request #44 and discussed in issue #42.
    Thanks to @hiroyuki-sato.
  - Implement new MTA/MSP module Sisimai::MSP::US::AmazonWorkMail for parsing
    a bounce mail via Amazon WorkMail. The module and test codes are imported
    from https://github.com/sisimai/p5-Sisimai/pull/162.
  - Implement new MTA/MSP module Sisimai::MSP::US::Office365 for parsing error 
    mails via Microsoft Office 365. The module, test codes, and sample emails
    are imported from https://github.com/sisimai/p5-Sisimai/pull/164.
  - New method `Sisimai::Address#to_s` to get an email address as String, it is
    implemented at pull-request #39. Thanks to @hiroyuki-sato.
  - Almost all of the class variables are removed for resolving issue #40 and
    merged pull-request #43, thanks to @hiroyuki-sato.

v4.14.2 - Ruby Version of Sisimai
--------------------------------------------------------------------------------
- release: "Wed,  3 Feb 2016 13:29:17 +0900 (JST)"
- version: "4.14.2"
- changes:
  - The first release of rb-Sisimai.

