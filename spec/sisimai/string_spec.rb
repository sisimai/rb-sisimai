require 'spec_helper'
require 'sisimai/string'

describe Sisimai::String do
  cn = Sisimai::String
  describe '.EOM' do
    v = '__END_OF_EMAIL_MESSAGE__'
    it('returns ' + v) { expect(cn.EOM()).to eq v }
  end

  describe '.token' do
    s = 'envelope-sender@example.jp'
    r = 'envelope-recipient@example.org'
    t = '239aa35547613b2fa94f40c7f35f4394e99fdd88'

    context 'valid arguments' do
      it("returns #{t}") { expect(cn.token(s,r,1)).to eq t }
      it('returns a token') { expect(cn.token(s,r,0)).not_to be_empty }
      it('returns ""') { expect(cn.token('', '', 0)).to be_empty }
      it("returns ''") { expect(cn.token(s, '', 0)).to be_empty }
      it("returns ''") { expect(cn.token('', r, 0)).to be_empty }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.token(nil) }.to raise_error(ArgumentError) }
      it('raises ArgumentError') { expect { cn.token(s) }.to raise_error(ArgumentError) }
      it('raises ArgumentError') { expect { cn.token(s, r) }.to raise_error(ArgumentError) }
    end
  end

  describe '.is_8bit' do
    context '7-bit string' do
      it('returns false') { expect(cn.is_8bit(8)).to be false }
      it('returns false') { expect(cn.is_8bit('neko')).to be false }
    end

    context 'empty string or nil' do
      it('returns nil') { expect(cn.is_8bit(nil)).to be nil }
      it('returns nil') { expect(cn.is_8bit('')).to be nil }
    end

    context '8-bit Strings' do
      it('returns true') { expect(cn.is_8bit('八')).to be true }
      it('returns true') { expect(cn.is_8bit('猫')).to be true }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.is_8bit }.to raise_error(ArgumentError) }
      it('raises ArgumentError') { expect { cn.is_8bit('x', 'y') }.to raise_error(ArgumentError) }
    end
  end

  describe '.sweep' do
    context 'valid string or nil' do
      it('returns "neko cat"') { expect(cn.sweep(' neko cat ')).to eq 'neko cat' }
      it('returns "nyaa !!"') { expect(cn.sweep(' nyaa   !!')).to eq 'nyaa !!' }
      it('returns nil') { expect(cn.sweep(nil)).to be nil }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { cn.sweep }.to raise_error(ArgumentError) }
      it('raises ArgumentError') { expect { cn.sweep('x', 'y') }.to raise_error(ArgumentError) }
    end
  end

end

