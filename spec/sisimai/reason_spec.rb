require 'spec_helper'
require 'sisimai/reason'
require 'sisimai/message'
require 'sisimai/mail'
require 'sisimai/data'

describe Sisimai::Reason do
  cn = Sisimai::Reason
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

  describe '.true' do
    mailboxobj = Sisimai::Mail.new('./set-of-emails/maildir/bsd/sendmail-01.eml')
    while r = mailboxobj.read do
      o = Sisimai::Message.new( data: r )
      v = Sisimai::Data.make( data: o )
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
