require 'spec_helper'
require 'sisimai/rhost'

describe 'Sisimai::Rhost' do
  describe 'Sisimai::Rhost.list() method' do
    v = Sisimai::Rhost.list()
    it 'list() returns a list' do
      expect(v.kind_of?(Array)).to be true
    end
  end

  describe 'Sisimai::Rhost.match() method' do
    it 'match(aspmx.l.google.com) returns True' do
      expect(Sisimai::Rhost.match('aspmx.l.google.com')).to be true
    end
    it 'match(example.jp) returns False' do
      expect(Sisimai::Rhost.match('example.jp')).to be false
    end
  end

  describe 'Sisimai::Rhost.get() method' do
    v = nil
    it 'get(v) returns reason text' do
      pending 'Tests will be added after implementation of Sisimai::Data class'
      expect(Sisimai::Rhost.get(v)).not_to be nil
    end
  end
end

