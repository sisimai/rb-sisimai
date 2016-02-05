require 'spec_helper'
require 'sisimai/time'

describe Sisimai::Time do
  cn = Sisimai::Time
  to = cn.new
  describe '.new' do
    it('returns Sisimai::Time object') { expect(to).to be_a Sisimai::Time }
  end

  describe '.to_json' do
    it('returns Integer') { expect(to.to_json).to be_a Integer }
    it('returns machine time') { expect(to.to_json).to eq(to.to_time.to_i) }
  end
end
