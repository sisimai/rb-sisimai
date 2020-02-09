require 'spec_helper'
require 'sisimai/order'

describe Sisimai::Order do
  cn = Sisimai::Order

  describe '.make' do
    pattern = cn.make('delivery failure')
    subject { pattern }
    it('returns Array') { is_expected.to be_a Array }
    it('have values')   { expect(pattern.size).to be > 0 }
    pattern.each do |e|
      it('is a module') { expect(e.class).to be_a Class }
      it('has a module name') { expect(e.to_s).to match(/\ASisimai::Lhost::/) }
    end
  end

  describe '.default' do
    default = cn.default
    subject { default }
    it('returns Array') { is_expected.to be_a Array }
    it('have values')   { expect(default.size).to be > 0 }
    default.each do |e|
      it('is a module') { expect(e.class).to be_a Class }
      it('has a module name') { expect(e.to_s).to match(/\ASisimai::Lhost::/) }
    end
  end

  describe '.another' do
    another = cn.another
    subject { another }
    it('returns Array') { is_expected.to be_a Array }
    it('have values')   { expect(another.size).to be > 0 }
    another.each do |e|
      it('is a module') { expect(e.class).to be_a Class }
      it('has a module name') { expect(e.to_s).to match(/\ASisimai::Lhost::/) }
    end
  end
end

