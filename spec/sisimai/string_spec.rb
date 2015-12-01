#require File.join(File.dirname(__FILE__), '../spec_helper')
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

    describe 'Valid Arguments' do
      context "(#{s}, #{r}, 1)" do
        it("returns #{t}") { expect(cn.token(s,r,1)).to eq t }
      end
      context "(#{s}, #{r}, 0)" do
        it('returns a token') { expect(cn.token(s,r,0)).not_to be_empty }
      end

      context '("", "", 0)' do
        it('returns ""') { expect(cn.token('', '', 0)).to be_empty }
      end
      context "(#{s}, '', 0)" do
        it("returns ''") { expect(cn.token(s, '', 0)).to be_empty }
      end
      context "('', #{r}, 0)" do
        it("returns ''") { expect(cn.token('', r, 0)).to be_empty }
      end
    end

    describe 'Wrong Number of Arguments' do
      context '(nil)' do
        it('raises ArgumentError') { expect { cn.token(nil) }.to raise_error(ArgumentError) }
      end
      context "(#{s})" do
        it('raises ArgumentError') { expect { cn.token(s) }.to raise_error(ArgumentError) }
      end
      context "(#{s}, #{r})" do
        it('raises ArgumentError') { expect { cn.token(s, r) }.to raise_error(ArgumentError) }
      end
    end
  end

  describe '.is_8bit' do
    describe '7-bit Strings' do
      context '(8)' do
        it('returns false') { expect(cn.is_8bit(8)).to be false }
      end
      context '(neko)' do
        it('returns false') { expect(cn.is_8bit('neko')).to be false }
      end
    end

    describe 'Empty String or nil' do
      context '(nil)' do
        it('returns nil') { expect(cn.is_8bit(nil)).to be nil }
      end
      context '("")' do
        it('returns nil') { expect(cn.is_8bit('')).to be nil }
      end
    end

    describe '8-bit Strings' do
      context '(八)' do
        it('returns true') { expect(cn.is_8bit('八')).to be true }
      end
      context '(猫)' do
        it('returns true') { expect(cn.is_8bit('猫')).to be true }
      end
    end

    describe 'Wrong number of Arguments' do
      context '()' do
        it('raises ArgumentError') { expect { cn.is_8bit }.to raise_error(ArgumentError) }
      end
      context '("x","y")' do
        it('raises ArgumentError') { expect { cn.is_8bit('x', 'y') }.to raise_error(ArgumentError) }
      end
    end
  end

  describe '.sweep' do
    describe 'Valid String or nil' do
      context '(" neko cat ")' do
        it('returns "neko cat"') { expect(cn.sweep(' neko cat ')).to eq 'neko cat' }
      end
      context '(" nyaa   !!")' do
        it('returns "nyaa !!"') { expect(cn.sweep(' nyaa   !!')).to eq 'nyaa !!' }
      end
      context '(nil)' do
        it('returns nil') { expect(cn.sweep(nil)).to be nil }
      end
    end

    describe 'Wrong Number of Arguments' do
      context '()' do
        it('raises ArgumentError') { expect { cn.sweep }.to raise_error(ArgumentError) }
      end
      context '("x","y")' do
        it('raises ArgumentError') { expect { cn.sweep('x', 'y') }.to raise_error(ArgumentError) }
      end
    end
  end

end

