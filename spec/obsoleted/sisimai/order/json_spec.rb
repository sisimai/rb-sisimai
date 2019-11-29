require 'spec_helper'
require 'sisimai/order/json'

describe Sisimai::Order::JSON do
  cn = Sisimai::Order::JSON
  describe '.default' do
    default = cn.default
    subject { default }
    it('returns Array') { is_expected.to be_a Array }
    it 'have values' do
      # pending 'Sisimai::Bite::JSON::* are not implemented yet'
      expect(default.size).to be > 0
    end
  end

  describe '.by("keyname")' do
    orderby = cn.by('keyname')
    subject { orderby }
    it('returns Hash') { is_expected.to be_a Hash }
    orderby.each_key do |e|
      it('is String') { expect(e).to be_a String }
      it('is Array') { expect(orderby[e]).to be_a Array }
      orderby[e].each do |f|
        it('is String') { expect(f).to be_a String }
        it('is a module name') { expect(f).to match(/\ASisimai::Lhost::/) }
      end
    end
  end
end


