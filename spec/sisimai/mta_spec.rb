require 'spec_helper'
require 'sisimai/mta'

describe Sisimai::MTA do
  describe '.INDICATORS' do
    it('returns Hash') { expect(Sisimai::MTA.INDICATORS).to be_a Hash }
  end
  describe '.DELIVERYSTATUS' do
    it('returns Hash') { expect(Sisimai::MTA.DELIVERYSTATUS).to be_a Hash }
  end
  describe '.index' do
    it('returns Array') { expect(Sisimai::MTA.index).to be_a Array }
  end
end
