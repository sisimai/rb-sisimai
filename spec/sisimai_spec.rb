require 'spec_helper'
require 'sisimai'

describe Sisimai do
  cn = Sisimai
  bH = 'bounceHammer'

  describe 'Sisimai::VERSION' do
    subject { Sisimai::VERSION }
    it('returns version') { is_expected.not_to be nil }
    it('returns String' ) { is_expected.to be_a(String) }
    it('matches X.Y.Z'  ) { is_expected.to match(/\A\d[.]\d+[.]\d+/) }
  end

  describe '.version' do
    subject { cn.version }
    it('is String') { is_expected.to be_a(String) }
    it('is ' + Sisimai::VERSION) { is_expected.to eq Sisimai::VERSION }
  end

  describe '.sysname' do
    subject { cn.sysname }
    it('is String')     { is_expected.to be_a(String) }
    it('returns ' + bH) { is_expected.to match(/bounceHammer/i) }
  end

  describe '.libname' do
    subject { cn.libname }
    it('is String')       { is_expected.to be_a(String) }
    it('returns Sisimai') { expect(cn.libname).to eq 'Sisimai' }
  end
end
