require 'spec_helper'
require 'sisimai/rfc1894'

describe Sisimai::RFC1894 do
  cn = Sisimai::RFC1894
  RFC1894Field1 = [
    'Reporting-MTA: dns; neko.example.jp',
    'Received-From-MTA: dns; mx.libsisimai.org',
    'Arrival-Date: Sun, 3 Jun 2018 14:22:02 +0900 (JST)',
  ]
  RFC1894Field2 = [
    'Final-Recipient: RFC822; kijitora@neko.example.jp',
    'X-Actual-Recipient: RFC822; sironeko@nyaan.jp',
    'Original-Recipient: RFC822; kuroneko@libsisimai.org',
    'Action: failed',
    'Status: 4.4.7',
    'Remote-MTA: DNS; [127.0.0.1]',
    'Last-Attempt-Date: Sat, 9 Jun 2018 03:06:57 +0900 (JST)',
    'Diagnostic-Code: SMTP; Unknown user neko@nyaan.jp',
  ]
  IsNotDSNField = [
    'Content-Type: message/delivery-status',
    'Subject: Returned mail: see transcript for details',
    'From: Mail Delivery Subsystem <MAILER-DAEMON@neko.example.jp>',
    'Date: Sat, 9 Jun 2018 03:06:57 +0900 (JST)',
  ]

  describe '.FIELDTABLE' do
    context '()' do
      v = cn.FIELDTABLE()
      it 'returns Hash' do
        expect(v).to be_a Hash
        expect(v.keys.size).to be > 0
      end
    end
  end

  describe '.match' do
    RFC1894Field1.each do |e|
      context "#{e}" do
        it('returns 1') { expect(Sisimai::RFC1894.match(e)).to eq 1 }
      end
    end

    RFC1894Field2.each do |e|
      context "#{e}" do
        it('returns 2') { expect(Sisimai::RFC1894.match(e)).to eq 2 }
      end
    end

    IsNotDSNField.each do |e|
      context "#{e}" do
        it('returns nil') { expect(Sisimai::RFC1894.match(e)).to be nil }
      end
    end
  end

  describe '.field' do
    RFC1894Field1.each do |e|
      v = cn.field(e)
      context "#{e}" do
        it('returns Array') { expect(v).to be_a Array }
        it 'include String' do
          expect(v[0]).to be_a String
          expect(v[0].size).to be > 0
          expect(v[1]).to be_a String
          expect(v[2]).to be_a String
          expect(v[3]).to be_a String
        end

        if v[3] == 'host'
          it('includes a sub type: DNS') { expect(v[1]).to match(/DNS/) }
          it('includes a "."') { expect(v[2]).to match(/[.]/) }
        else
          it('is an empty string') { expect(v[1]).to be_empty }
        end
        it('v[3] is a "host" or "date"') { expect(v[3]).to match(/\A(?:host|date)\z/) }
      end
    end

    RFC1894Field2.each do |e|
      v = cn.field(e)
      context "#{e}" do
        it('returns Array') { expect(v).to be_a Array }
        it 'include String' do
          expect(v[0]).to be_a String
          expect(v[0].size).to be > 0
          expect(v[1]).to be_a String
          expect(v[2]).to be_a String
          expect(v[3]).to be_a String
        end

        if v[3] =~ /\A(?:host|addr|code)\z/
          it('includes a sub type:') { expect(v[1]).to match(/(?:DNS|RFC822|SMTP|X-.+)/) }
          it('includes a "."') { expect(v[2]).to match(/[.]/) }
        else
          it('is an empty string') { expect(v[1]).to be_empty }
        end
        it('v[3] is a valid group') { expect(v[3]).to match(/\A(?:host|date|addr|list|stat|code)\z/) }
      end
    end

    IsNotDSNField.each do |e|
      context "#{e}" do
        it('returns nil') { expect(Sisimai::RFC1894.match(e)).to be nil }
      end
    end
  end
end

