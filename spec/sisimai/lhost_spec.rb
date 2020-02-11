require 'spec_helper'
require 'sisimai/lhost'

describe Sisimai::Lhost do
  describe '.DELIVERYSTATUS' do
    it('returns Hash') { expect(Sisimai::Lhost.DELIVERYSTATUS).to be_a Hash }
  end
  describe '.INDICATORS' do
    it('returns Hash') { expect(Sisimai::Lhost.INDICATORS).to be_a Hash }
  end
  describe '.smtpagent' do
    it('returns String') { expect(Sisimai::Lhost.smtpagent).to be_a Object::String }
  end
  describe '.description' do
    it('returns String') { expect(Sisimai::Lhost.description).to be_a ::String }
    it('is empty string') { expect(Sisimai::Lhost.description).to be_empty }
  end
  describe '.index' do
    it('returns Array') { expect(Sisimai::Lhost.index).to be_a Array }
    it('is not empty' ) { expect(Sisimai::Lhost.index.size).to be > 0 }
  end
  describe '.path' do
    it('returns Hash') { expect(Sisimai::Lhost.path).to be_a Hash }
    it('is not empty' ) { expect(Sisimai::Lhost.path.size).to be > 0 }
  end
  describe '.make' do
    it('returns nil') { expect(Sisimai::Lhost.make).to be nil }
  end
end
