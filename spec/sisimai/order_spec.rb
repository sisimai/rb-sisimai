require 'spec_helper'
require 'sisimai/order'

describe Sisimai::Order do
  cn = Sisimai::Order
  describe '.default' do
    it('returns Array') { expect(cn.default).to be_a Array }
  end
  describe '.another' do
    it('returns Array') { expect(cn.another).to be_a Array }
  end

  describe '.headers' do
    it('returns Hash') { expect(cn.headers).to be_a Hash }
  end

  describe '.by("subject")' do
    it('returns Hash') { expect(cn.by).to be_a Hash }
  end
end

