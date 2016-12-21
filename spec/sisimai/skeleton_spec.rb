require 'spec_helper'
require 'sisimai/skeleton'

describe Sisimai::Skeleton do
  cn = Sisimai::Skeleton
  describe '.INDICATORS' do
    it('returns Hash') { expect(cn.INDICATORS).to be_a Hash }
    it('have 2 keys' ) { expect(cn.INDICATORS.keys.size).to be == 2 }
  end
  describe '.DELIVERYSTATUS' do
    it('returns Hash') { expect(cn.DELIVERYSTATUS).to be_a Hash }
    it('have >0 keys' ) { expect(cn.DELIVERYSTATUS.keys.size).to be > 0 }
  end
end


