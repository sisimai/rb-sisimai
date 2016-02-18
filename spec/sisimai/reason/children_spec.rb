require 'spec_helper'

reasonchildren = {
  'Blocked' => [ '550 Access from ip address 192.0.2.1 blocked.' ],
  'ContentError' => [ '550 5.6.0 the headers in this message contain improperly-formatted binary content' ],
  'ExceedLimit' => [ '5.2.3 Message too large' ],
  'Expired' => [ '421 4.4.7 Delivery time expired' ],
  'Filtered' => [ '550 5.1.2 User reject' ],
  'HasMoved' => [ '550 5.1.6 address neko@cat.cat has been replaced by neko@example.jp' ],
  'HostUnknown' => [ '550 5.2.1 Host Unknown' ],
  'MailboxFull' => [ '450 4.2.2 Mailbox full' ],
  'MailerError' => [ 'X-Unix; 255' ],
  'MesgTooBig' => [ '400 4.2.3 Message too big' ],
  'NetworkError' => [ '554 5.4.6 Too many hops' ],
  'NoRelaying' => [ '550 5.0.0 Relaying Denied' ],
  'NotAccept' => [ '556 SMTP protocol returned a permanent error' ],
  'OnHold' => [ '5.0.901 error' ],
  'Rejected' => [ '550 5.1.0 Address rejected' ],
  'SecurityError' => [ '570 5.7.7 Email not accepted for policy reasons' ],
  'SpamDetected' => [ '570 5.7.7 Spam Detected' ],
  'Suspend' => [ '550 5.0.0 Recipient suspend the service' ],
  'SystemError' => [ '500 5.3.5 System config error' ],
  'SystemFull' => [ '550 5.0.0 Mail system full' ],
  'TooManyConn' => [ '421 Too many connections' ],
  'UserUnknown' => [ '550 5.1.1 Unknown User' ],
}

reasonchildren.each_key do |e|
  rn = 'Sisimai::Reason::' + e
  require rn.downcase.gsub('::', '/')
  cn = Module.const_get(rn)

  describe cn do
    describe '.text' do
      it('returns reason name') { expect(cn.text).to be == e.downcase }
    end

    describe '.description' do
      it('returns String') { expect(cn.description).to be_a String }
      it('returns description') { expect(cn.description.size).to be > 0 }
    end

    describe '.true' do
      it('returns nil') { expect(cn.true(nil)).to be nil }
    end

    describe '.match' do
      reasonchildren[e].each do |r|
        next if e == 'OnHold'
        it('returns true') { expect(cn.match(r)).to be true }
      end
    end
  end
end

%w|Delivered Feedback Undefined Vacation|.each do |e|
  rn = 'Sisimai::Reason::' + e
  require rn.downcase.gsub('::', '/')
  cn = Module.const_get(rn)

  describe cn do
    describe '.text' do
      it('returns reason name') { expect(cn.text).to be == e.downcase }
    end

    describe '.description' do
      it('returns String') { expect(cn.description).to be_a String }
      it('returns description') { expect(cn.description.size).to be > 0 }
    end

    describe '.true' do
      it('returns nil') { expect(cn.true(nil)).to be nil }
    end

    describe '.match' do
      it('returns nil') { expect(cn.true(nil)).to be nil }
    end
  end
end

