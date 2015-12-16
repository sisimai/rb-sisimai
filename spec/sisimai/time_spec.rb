require 'spec_helper'
require 'sisimai/time'

describe Sisimai::Time do
  cn = Sisimai::Time
  to = cn.new
  describe '.new' do
    it('returns Sisimai::Time object') { expect(to).to be_a Sisimai::Time }
  end
end
