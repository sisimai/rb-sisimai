require 'spec_helper'
require 'sisimai/reason'
require 'sisimai/message'
require 'sisimai/mail'
require 'sisimai/data'

describe Sisimai::Reason do
  cn = Sisimai::Reason

  smtperrors = [
    %q|smtp; 550 5.1.1 <kijitora@example.co.jp>... User Unknown|,
    %q|smtp; 550 Unknown user kijitora@example.jp|,
    %q|smtp; 550 5.7.1 can't determine Purported |,
    %q|unknown; No such domain.|,
    %q|X-Notes; ユーザー ka (kijitora@example.co.jp) は Domino ディレクトリ|,
    %q|SMTP; 550 5.2.1 The email account that you tried to reach is disabled. g0000000000ggg.00|,
    %q|smtp; 550 Unknown user kijitora@example.co.jp|,
    %q|smtp; 550 5.1.1 <kijitora@example.jp>... User unknown|,
    %q|smtp; 550 5.1.1 <kijitora@example.or.jp>... User unknown|,
    %q|x-unix; procmail: Couldn't create "/var/spool/mail/neko" id:|,
    %q|smtp; 550 5.2.1 <filtered@example.co.jp>... User Unknown|,
    %q|smtp; 550 5.1.1 <userunknown@example.co.jp>... User Unknown|,
    %q|smtp; 550 Unknown user kijitora@example.net|,
    %q|smtp; 550 5.1.1 Address rejected|,
    %q|smtp; 450 4.1.1 <kijitora@example.org>: Recipient address|,
    %q|X-Postfix; Host or domain name not found. Name service error|,
    %q|X-mPOP-Fallback_MX; connect to example.com[93.184.216.119]:|,
    %q|smtp; 452 4.3.2 Connection rate limit exceeded.|,
    %q|smtp; 553 5.1.8 <root@vagrant-centos65.vagrantup.com>...|,
    %q|smtp; 553 5.1.8 <root@vagrant-centos65.vagrantup.com>...|,
    %q|smtp; 553 5.1.8 <root@vagrant-centos65.vagrantup.com>...|,
    %q|smtp; 550 5.1.1 <userunknown@cubicroot.jp>... User Unknown|,
    %q|smtp; 550 5.2.1 <kijitora@example.jp>... User Unknown|,
    %q|smtp; 550 5.2.2 <noraneko@example.jp>... Mailbox Full|,
    %q|X-Postfix; unknown user: "kijitora"|,
    %q|X-Postfix; connect to|,
    %q|smtp; 550 5.1.6 recipient no longer on server: kijitora@example.go.jp|,
    %q|X-Postfix; Name service error for name=example.org|,
    %q|smtp; 550 5.7.1 Unable to relay for relay_failed@testreceiver.com|,
    %q|smtp; 550 Access from ip address 87.237.123.24 blocked. Visit|,
    %q|SMTP; 550 5.1.1 <userunknown@bouncehammer.jp>... User Unknown|,
    %q|smtp;  550 'arathib@vnet.IBM.COM' is not a|,
    %q|smtp; 550 user unknown|,
    %q|smtp; 426 connection timed out|,
    %q|smtp;550 5.2.1 <kijitora@example.jp>... User Unknown|,
    %q|smtp; 550 5.7.1 Message content rejected, UBE, id=00000-00-000|,
    %q|x-unix; Quota exceeded message delivery failed to|,
    %q|550 5.1.1 sid=i01K1n00l0kn1Em01 Address rejected foobar@foobar.com. [code=28] |,
    %q|554 imta14.emeryville.ca.mail.comcast.net comcast 192.254.113.140 Comcast block for spam.  Please see http://postmaster.comcast.net/smtp-error-codes.php#BL000000 |,
    %q|x-unix; Quota exceeded message delivery failed to|,
    %q|X-Postfix; temporary failure. Command output: avpcheck: unable|,
    %q|SMTP; 550 5.1.1 User unknown|,
    %q|smtp; 550 5.1.1 <kijitora@example.jp>... User Unknown|,
    %q|smtp; 550 5.2.1 <mikeneko@example.jp>... User Unknown|,
    %q|smtp; 550 5.2.2 <sabineko@example.jp>... Mailbox Full|,
    %q|X-Yandex; connect to 6jo.example.jp[192.0.2.79]:25:|,
    %q|SMTP; 550 5.1.1 <userunknown@bouncehammer.jp>... User Unknown|,
    %q|SMTP; 550 5.1.1 <userunknown@example.org>... User Unknown|,
    %q|SMTP; 550 5.2.1 <filtered@example.com>... User Unknown|,
    %q|SMTP; 550 5.1.1 <userunknown@example.co.jp>... User Unknown|,
    %q|SMTP; 553 5.1.8 <httpd@host1.mx.example.jp>... Domain of sender|,
    %q|SMTP; 552 5.2.3 Message size exceeds fixed maximum message size (10485760)|,
    %q|SMTP; 550 5.6.9 improper use of 8-bit data in message header|,
    %q|SMTP; 554 5.7.1 <kijitora@example.org>: Relay access denied|,
    %q|SMTP; 450 4.7.1 Access denied. IP name lookup failed [192.0.2.222]|,
    %q|SMTP; 554 5.7.9 Header error|,
    %q|SMTP; 450 4.7.1 <c135.kyoto.example.ne.jp[192.0.2.56]>: Client host rejected: may not be mail exchanger|,
    %q|X-Unix; 77|,
    %q|SMTP; 554 IP=192.0.2.254 - A problem occurred. (Ask your postmaster for help or to contact neko@example.org to clarify.) (BL)|,
    %q|SMTP; 551 not our user|,
    %q|X-Unix; 255|,
    %q|SMTP; 550 Unknown user kijitora@ntt.example.ne.jp|,
    %q|SMTP; 554 5.4.6 Too many hops|,
    %q|SMTP; 551 not our customer|,
    %q|SMTP; 550-5.7.1 [180.211.214.199       7] Our system has detected that this message is|,
    %q|SMTP; 550 Host unknown|,
    %q|SMTP; 550 5.1.1 <=?utf-8?B?8J+QiPCfkIg=?=@example.org>... User unknown|,
    %q|smtp; 550 kijitora@example.com... No such user|,
    %q|smtp; 554 Service currently unavailable|,
    %q|smtp; 554 Service currently unavailable|,
    %q|smtp; 550 maria@dest.example.net... No such user|,
    %q|smtp; 5.1.0 - Unknown address error 550-'5.7.1 <000001321defbd2a-788e31c8-2be1-422f-a8d4-cf7765cc9ed7-000000@email-bounces.amazonses.com>... Access denied' (delivery attempts: 0)|,
    %q|smtp; 5.3.0 - Other mail system problem 550-'Unknown user this-local-part-does-not-exist-on-the-server@docomo.ne.jp' (delivery attempts: 0)|,
    %q|smtp; 5.1.0 - Unknown address error 550-'5.2.2 <kijitora@example.jp>... Mailbox Full' (delivery attempts: 0)|,
    %q|smtp; 5.4.7 - Delivery expired (message too old) 'timeout' (delivery attempts: 0)|,
    %q|X-Outbound-Mail-Relay; Host or domain name not found. Name|,
    %q|smtp; 550 5.2.2 <kijitora@example.co.jp>... Mailbox Full|,
    %q|smtp; 550 5.2.2 <sabineko@example.jp>... Mailbox Full|,
    %q|smtp; 550 5.1.1 <mikeneko@example.jp>... User Unknown|,
    %q|smtp; 550 5.1.1 <kijitora@example.co.jp>... User Unknown|,
    %q|SMTP; 553 Invalid recipient destinaion@example.net (Mode: normal)|,
    %q|smtp; 550 5.1.1 RCP-P2 http://postmaster.facebook.com/response_codes?ip=192.0.2.135#rcp Refused due to recipient preferences|,
    %q|SMTP; 550 5.1.1 RCP-P1 http://postmaster.facebook.com/response_codes?ip=192.0.2.54#rcp |,
    %q|smtp;550 5.2.2 <kijitora@example.jp>... Mailbox Full|,
    %q|smtp;550 5.1.1 <kijitora@example.jp>... User Unknown|,
    %q|smtp;554 The mail could not be delivered to the recipient because the domain is not reachable. Please check the domain and try again (-1915321397:308:-2147467259)|,
    %q|smtp;550 5.1.1 <sabineko@example.co.jp>... User Unknown|,
    %q|smtp;550 5.2.2 <mikeneko@example.co.jp>... Mailbox Full|,
    %q|smtp;550 Requested action not taken: mailbox unavailable (-2019901852:4030:-2147467259)|,
    %q|smtp;550 5.1.1 <kijitora@example.or.jp>... User unknown|,
    %q|550 5.1.1 <kijitora@example.jp>... User Unknown |,
    %q|550 5.1.1 <this-local-part-does-not-exist-on-the-server@example.jp>... |,
    %q|Connection timed out|,
  ]

  describe '.get' do
    it('returns nil') { expect(cn.get(nil)).to be nil }
  end

  describe '.anotherone' do
    it('returns nil') { expect(cn.anotherone(nil)).to be nil }
  end
  
  describe '.index' do
    it('returns Array') { expect(cn.index).to be_a Array }
    it('include reasons') { expect(cn.index.size).to be > 0 }
  end

  describe '.retry' do
    it('returns Array') { expect(cn.retry).to be_a Array }
    it('include reasons') { expect(cn.retry.size).to be > 0 }
  end

  describe '.match' do
    smtperrors.each do |e|
      v = cn.match(e)
      subject { v }
      it('returns String') { is_expected.to be_a String }
      it('returns reason: '+ v) { is_expected.to match(/\A[a-z]+\z/) }
    end
  end

  describe '.true' do
    mailboxobj = Sisimai::Mail.new('./set-of-emails/maildir/bsd/sendmail-01.eml')
    while r = mailboxobj.read do
      o = Sisimai::Message.new( { 'data' => r } )
      v = Sisimai::Data.make( { 'data' => o } )
      it('returns Array') { expect(v).to be_a Array }

      v.each do |e|
        it('is Sisimai::Data object') { expect(e).to be_a Sisimai::Data }
        it 'is bounced due to "userunkonwn"' do
          expect(e.reason).to be == 'userunknown'
        end
      end
    end
  end

end
