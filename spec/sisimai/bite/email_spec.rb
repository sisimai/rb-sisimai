require 'spec_helper'
require 'sisimai/bite/email'

describe Sisimai::Bite::Email do
  describe '.INDICATORS' do
    it('returns Hash') { expect(Sisimai::Bite::Email.INDICATORS).to be_a Hash }
  end
  describe '.headerlist' do
    it('returns Array') { expect(Sisimai::Bite::Email.headerlist).to be_a Array }
    it('is empty list') { expect(Sisimai::Bite::Email.headerlist).to be_empty }
  end
  describe '.pattern' do
    it('returns Array') { expect(Sisimai::Bite::Email.pattern).to be_a Array }
    it('is empty list') { expect(Sisimai::Bite::Email.pattern).to be_empty }
  end
  describe '.index' do
    it('returns Array') { expect(Sisimai::Bite::Email.index).to be_a Array }
    it('is not empty' ) { expect(Sisimai::Bite::Email.index.size).to be > 0 }
  end
  describe '.scan' do
    it('returns nil') { expect(Sisimai::Bite::Email.scan).to be nil }
  end
end


