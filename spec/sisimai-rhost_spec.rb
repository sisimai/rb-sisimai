require 'spec_helper'
require 'sisimai/rhost'

describe 'Sisimai::Rhost' do
  describe 'Sisimai::Rhost.list() method' do
    v = Sisimai::Rhost.list()
    it 'list() returns a list' do
      expect(v.kind_of?(Array)).to be_true
    end
  end
  describe 'Sisimai::Rhost.match() method' do
    it 'match(aspmx.l.google.com) returns True' do
      expect(Sisimai::Rhost.match('aspmx.l.google.com')).to be_true
    end
    it 'match(example.jp) returns False' do
      expect(Sisimai::Rhost.match('example.jp')).to be_false
    end
  end
end

