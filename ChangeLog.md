RELEASE NOTES for Ruby version of Sisimai
================================================================================
- releases: "https://github.com/sisimai/rb-Sisimai/releases"
- download: "https://rubygems.org/gems/sisimai"

v4.25.0p4
--------------------------------------------------------------------------------
- release: ""
- version: ""
- changes:
  - Check the format of the value of `Message-Id` header for detecting a bounce
    mail from Exim or not.
  - Call `Sisimai::Rhost::FrancePTT` module when the value of `rhost` includes
    `.wanadoo.fr`.
  - Fix code at `Sisimai::Message::Email.takeapart` method to decode a Subject
    header of the original message.
  - #147 Update error messages for Low Reputation Error from Gmail.
  - Parser code to read bounce mails from m-FILTER at `Sisimai::Message::Email`
    has been improved.
  - Status 5.4.1 from Exchange Online is classified into "rejected" reason.

v4.25.0
--------------------------------------------------------------------------------
- release: "Tue,  9 Apr 2019 11:22:22 +0900 (JST)"
- version: "4.25.0"
- changes:
  - Implement new class `Sisimai::RFC1894` for parsing message/delivery-status
    part. #133
  - Experimental implementation at the following MTA, Rhost modules:
    - `Sisimai::Bite::Email::Amavis`: amavisd-new
    - `Sisimai::Rhost::TencentQQ`: Tencent QQ (mail.qq.com)
  - Remove unused methods and variables
    - `Sisimai::DateTime.hourname`
    - `$Sisimai::DateTime::HourNames`
    - `Sisimai::RFC5322.is_domainpart`
  - Code refactoring: less lines of code and shallower indentation.
  - Build test for JRuby on Travis CI was temporarily disabled. #138
  - Sisimai works on Ruby 2.6.0
  - Fix `Sisimai::ARF.is_arf` method to remove angle brackets:`<` and `>` from
    `From:` header.
  - Fix serious bug (Hash key typo) in `Sisimai::Rhost::Google`
  - Less Symbol, less `String#to_sym`.
  - Remove `set-of-emails/logo` directory because we cannot change the license
    of each file in the directory to The 2-Clause BSD License.
  - Update error message patterns in the following modules:
    - `Sisimai::Reason::Blocked` (hotmail, ntt docomo)
    - `Sisimai::Reason::PolicyViolation` (postfix)
    - `Sisimai::Reason::Rejected` (postfix)
    - `Sisimai::Reason::SystemError` (hotmail)
    - `Sisimai::Reason::TooManyConn` (ntt docomo)
    - `Sisimai::Reason::UserUnknown` (hotmail)
    - `Sisimai::Bite::Email::McAfee` (userunknown)
    - `Sisimai::Bite::Email::Exchange2007` (securityerror)
  - The order of `Sisimai::Bite::Email` modules to be loaded has been changed:
    Load Office365 and Outlook prior to Exchange2007 and Exchange2003.
  - Update the followng MTA modules for improvements and bug fixes:
    - `Sisimai::Bite::Email::Exchange2007`
  - MIME Decoding in `Subject:` header improved.
  - Bug fix in `Sisimai::MIME.is_mimeencoded` method.
  - Make stable the order of MTA modules which have MTA specific email headers
    at `Sisimai::Order::Email.headers` method.

v4.24.1
--------------------------------------------------------------------------------
- release: "Wed, 14 Nov 2018 11:09:44 +0900 (JST)"
- version: "4.24.1"
- changes:
  - Fix bug in Sisimai::RFC3464: scan method unintentionally detects non-bounce
    mail as a bounce.
  - Remove unused method Sisimai::DateTime.o2d

v4.24.0
--------------------------------------------------------------------------------
- release: "Thu,  1 Nov 2018 18:00:00 +0900 (JST)"
- version: "4.24.0"
- changes:
  - Variable improvement (remove redundant substitution)
  - Remove Sisimai::RFC2606 (Unused module)
  - MIME decoding improvement #130 Thanks to @outreach-soren.
    - Implement Sisimai::MIME.makeflat
    - Implement Sisimai::MIME.breaksup
    - Call Sisimai::MIME.makeflat at Sisimai::Message::Email.parse
    - Other related updates in Sisimai::Bite::Email::*
  - Tiny improvement in Sisimai::String.to_plain
  - Update "blocked" error message patterns for iCloud.
    - A client IP address has no PTR record
    - Invalid HELO/EHLO name

v4.23.0
--------------------------------------------------------------------------------
- release: "Fri, 31 Aug 2018 20:19:54 +0900 (JST)"
- version: "4.23.0"
- changes:
  - #124 Implement Sisimai::Mail::Memory class for reading bounce messages from
    memory(variable).
  - Update regular expression in Sisimai::Bite::Email::Office365 for detecting
    failure on SMTP RCPT.
  - #126 Fix awful bugs(NoMethodError) in Sisimai::Bite::Email::Biglobe, EZweb,
    and KDDI. Thanks to @rinmu.
  - #128 Less method calls: use method chain, bang method.
  - Import commit  sisimai/p5-Sisimai@cccb4ef Some test code have been loosened
    for UTC+13(Pacific/Tongatapu), UTC+14(Pacific/Kiritimati).
  - #127 Fix "NoMethodError" in Sisimai::Bite::Email::Postfix when the value of
    Diagnostic-Code field is folded. Thanks to @Unknown22.

v4.22.7
--------------------------------------------------------------------------------
- release: "Mon, 16 Jul 2018 13:02:54 +0900 (JST)"
- version: "4.22.7"
- changes:
  - Register D.S.N. "4.4.312" and "5.4.312" on Office 365 as "networkerror".
  - Fix error message pattern in Sisimai::Reason::SecurityError.
  - Fix code to get the original Message-Id field which continued to the next
    line. Thanks to Andreas Mock.
  - Update error message pattern in Sisimai::Reason::SpamDetected.
  - Add 15 sample emails for Postfix, Outlook and others.
  - Add 3 sample emails for Sisimai::RFC3464.
  - Add 2 sample vacation emails for Sisimai::RFC3834.

v4.22.6
--------------------------------------------------------------------------------
- release: "Wed, 23 May 2018 20:00:00 +0900 (JST)"
- version: ""
- changes:
  - #115 Fix bug in Sisimai::MIME.qprintd().
  - Error message patterns in Sisimai::Reason::Filtered have been replaced with
    fixed strings.
  - #116 Remove sample email files listed in sisimai/set-of-emails#6 to clarify
    copyrights.
  - The value of "softbounce" in the parsed results is always "1" when a reason
    is "undefined" or "onhold".
  - #117 Less regular expression in each class of Sisimai::Bite::Email.
  - #118 Cool logo for "set-of-emails". Thanks to @batarian71.
  - #119 Implement Sisimai::Rhost::KDDI for detecting a bounce reason of au via
    msmx.au.com or lsean.ezweb.ne.jp. Thanks to @kokubumotohiro.
  - Update sample emails and codes for getting error messages in bounced emails
    on Oath(Yahoo!).
  - Add many sample emails for "notaccept" and "rejected".

v4.22.5
--------------------------------------------------------------------------------
- release: "Fri, 30 Mar 2018 12:29:36 +0900 (JST)"
- version: "4.22.5"
- changes:
  - #112 The order to load MTA modules improvement.
  - Sample emails in set-of-emails/ which are not owned by Sisimai project have
    been removed.
  - Update error message patterns in Sisimai::Reason::Expired.
  - Less regular expression in each child class of Sisimai::Reason #113.
  - Pre-Updates for au.com, the new domain of EZweb from Apr 2018 announced at
    http://news.kddi.com/kddi/corporate/newsrelease/2017/08/22/2637.html #114

v4.22.4
--------------------------------------------------------------------------------
- release: "Wed, 14 Feb 2018 10:44:00 +0900 (JST)"
- version: "4.22.4"
- changes:
  - Import commit sisimai/p5-Sisimai@8c6eb33, Add status code 4.7.25 (RFC-7372)
    as "blocked".
  - The following performance improvements makes 1.49 times faster.
    - It makes rb-Sisimai on JRuby 1.16 times faster.
    - #96 String#+ and sprintf replaced with String#<< at Pull-Request #103.
    - #98 loop do replaced with while(true) at Pull-Request #104.
    - #99 String#=~ and regular expressions /\A...\z/, /\A.../ or /...\z/ have
      been replaced with String#start_with?, String#end_with?, String#include?,
      Array#include?, or String#== at Pull-Request #105, #107, #108.
    - #102 String#sub(/...\z/, '...') has been replaced with String#chomp, or
      String#strip, String#lstrip, String#rstrip at Pull-Request #106.
    - Import Pull-Request sisimai/p5-Sisimai#258, remove /i modifier from each
      regular expressions as possible and call String#downcase before matching.
    - Pull-Request #111, Some Array#each have been replaced with Array#shift in
      while loop.

v4.22.3
--------------------------------------------------------------------------------
- release: "Tue, 26 Dec 2017 09:22:22 +0900 (JST)"
- version: "4.22.3"
- changes:
  - Issue #88: Fix codes in Sisimai.DateTime.parse() for setting numeric values
    using sprintf(). Thanks to @phuong1492.
  - Import Pull-Request sisimai/p5-Sisimai#239, add error message patterns for
    laposte.net and orange.fr.
  - Import Pull-Req sisimai/p5-Sisimai#244 to follow up sisimai/p5-Sisimai#239.
    More support for Orange and La Poste.
  - Import Pull-Request sisimai/p5-Sisimai#245, update error message patterns
    of SFR and Free.fr.
  - Import Pull-Request sisimai/p5-Sisimai#246, large scale updates for Exim
    and error message patterns.
  - Merge Pull-Request #93 from @subuta to fix issue #92. Sisimai.make() method
    passes ActiveSupport::HashWithIndifferentAccess object with `input: "json"`
    parameter. Thanks to @subuta.
  - Import Pull-Request sisimai/p5-Sisimai#247, Add 100+ error message patterns
    into the following reason classes: Blocked, Expired, Filtered, HostUnknown,
    PolicyViolation, MailboxFull, NetworkError, NoRelaying, Rejected, Suspend,
    SpamDetected, SystemError, TooManyConn, and UserUnknown.
  - Fix bug in a regular expression object for concatenating error messages in
    Sisimai::Bite::Email::Exim.
  - Fix a wrong regular expression for detecting a recipient address and error
    messages in Sisiamai::Bite::Email::IMailServer.
  - Import Pull-Request sisimai/p5-Sisimai#247: Improved code at Sisimai::Data
    to remove string like "550-5.1.1" from an error message for to be matched
    exactly with regular expressions defined in each class of Sisimai::Reason.
  - Fixed issue #91, Import and convert error messages and reasons table from
    Sisimai::Bite::Email::Exchange2007 into Sisimai::Rhost::ExchangeOnline for
    detecting an error reason. Thanks to @joaoscotto.
  - Fix code to avoid an error with "invalid byte sequence in UTF-8" reported
    at https://heartbeats.jp/hbblog/2017/12/sisimai.html .
  - Implement Sisimai::Bite::Email::FML to parse bounce mails generated by fml
    mailing list server/manager. Thanks to @ttkzw.

v4.22.2
--------------------------------------------------------------------------------
- release: "Fri, 13 Oct 2017 11:59:53 +0900 (JST)"
- version: "4.22.2"
- changes:
  - Apply Pull-Request #84 (issue #83) for setting the value of `softorhard` in 
    `Sisimai::SMTP::Error.soft_or_hard` method. Thanks to @lunatyq.
  - Fix a wrong value assignment, and code for Performance/StartWith reported
    from Rubocop in Sisimai::Bite::Email::GSuite.
  - Update codes about Lint/AssignmentInCondition, Style/Next, Style/EmptyElse,
    Style/UselessAssignment, and others reported from Rubocop.
  - Fix code for Performance/Casecmp, Performance/LstripRstrip in Sisimai::MIME.
  - Update code for Style/SymbolProc in Sisimai::Message::Email.
  - Support parsing JSON object from SendGrid Event Webhook.
  - Suuport "event": "spamreport" via Feedback Loop on SendGrid Event Webhook.
  - Implement `Sisimai::Address.is_undisclosed` method.
  - Import Pull-Request #237: Support parsing bounce mail from GoDaddy.
  - Fix bug for setting the value of `date` in Sisimai::Bite::Email::Postfix.
  - Remove obsoleted classes: Sisimai::MTA, Sisimai::MSP, and Sisimai::CED.
  - Remove obsoleted method: `Sisimai::Address.parse`.

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
    - https://libsisimai.org/en/usage#callback
    - https://libsisimai.org/ja/usage#callback
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

