require 'spec_helper'
require 'sisimai/mta'

describe Sisimai::MTA do
  cn = Sisimai::MTA

  describe '.INDICATORS' do
    it('returns Hash') { expect(cn.INDICATORS).to be_a Hash }
  end
  describe '.DELIVERYSTATUS' do
    it('returns Hash') { expect(cn.DELIVERYSTATUS).to be_a Hash }
  end
  describe '.index' do
    it('returns Array') { expect(cn.index).to be_a Array }
  end
end
