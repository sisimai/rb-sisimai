require 'spec_helper'
require 'sisimai/bite/json'

describe Sisimai::Bite::JSON do
  describe '.headerlist' do
    it('returns Array') { expect(Sisimai::Bite::JSON.headerlist).to be_a Array }
    it('is empty list') { expect(Sisimai::Bite::JSON.headerlist).to be_empty }
  end
  describe '.index' do
    it('returns Array') { expect(Sisimai::Bite::JSON.index).to be_a Array }
    it('is not empty' ) { expect(Sisimai::Bite::JSON.index.size).to be > 0 }
  end
  describe '.scan' do
    it('returns nil') { expect(Sisimai::Bite::JSON.scan).to be nil }
  end
  describe '.adapt' do
    it('returns nil') { expect(Sisimai::Bite::JSON.adapt).to be nil }
  end
end

