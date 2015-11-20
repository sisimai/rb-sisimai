require 'spec_helper'

describe Sisimai do
  cn = Sisimai
  v  = cn::VERSION
  describe 'Sisimai::VERSION' do
    it('has a version number')   { expect(cn::VERSION).not_to be nil }
    it('version number is ' + v) { expect(cn::VERSION).to eq v }
  end

  describe '.version' do
    it('returns ' + v) { expect(cn.version).to eq v }
  end

  describe '.sysname' do
    it('returns "bouncehammer"') { expect(cn.sysname).to eq 'bouncehammer' }
  end

  describe '.libname' do
    it('returns ' + cn.libname) { expect(cn.libname).to eq 'Sisimai' }
  end
end
