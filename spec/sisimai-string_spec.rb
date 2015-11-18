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

    context 'Valid Arguments' do
      example("(#{s}, #{r}, 1) returns #{t}")    { expect(cn.token(s,r,1)).to eq t }
      example("(#{s}, #{r}, 0) returns a token") { expect(cn.token(s,r,0)).not_to be_empty }
    end

    context 'Invalid Arguments' do
      example('("","",0) returns ""')     { expect(cn.token("","",0)).to be_empty }
      example("(#{s}, '', 0) returns ''") { expect(cn.token(s,"",0)).to be_empty }
      example("('', #{r}, 0) returns ''") { expect(cn.token("",r,0)).to be_empty }
    end

    context 'Wrong Number of Arguments' do
      example('(nil) raises ArgumentError')       { expect { cn.token(nil) }.to raise_error(ArgumentError) }
      example("(#{s}) raises ArgumenetError")     { expect { cn.token(s) }.to raise_error(ArgumentError) }
      example("(#{s}, #{r}) raises ArgumentError"){ expect { cn.token(s,r) }.to raise_error(ArgumentError) }
    end
  end

  describe '.is_8bit' do
    example('(8) returns false')    { expect(cn.is_8bit(8)).to be false }
    example('(neko) returns false') { expect(cn.is_8bit('neko')).to be false }
    example('(nil) returns false')  { expect(cn.is_8bit(nil)).to be nil }

    context '8-bit Strings' do
      example('(八) returns true')  { expect(cn.is_8bit('八')).to be true }
      example('(猫) returns true') { expect(cn.is_8bit('猫')).to be true }
    end

    context 'Wrong number of Arguments' do
      example('() raises ArgumentError') { expect { cn.is_8bit() }.to raise_error(ArgumentError) }
    end
  end

  describe 'Sisimai::String.sweep() method' do
    it '.sweep(nil) returns nil' do
      expect(Sisimai::String.sweep(nil)).to be_nil
    end

    it '.sweep(" neko cat ") returns "neko cat"' do
      expect(Sisimai::String.sweep(' neko cat ')).to eq 'neko cat'
    end

    it '.sweep(" nyaa   !!") returns "nyaa !!"' do
      expect(Sisimai::String.sweep(' nyaa   !!')).to eq 'nyaa !!'
    end

    context 'Errors from the method' do
      it '.sweep() raise an error: ArgumentError' do
        expect { Sisimai::String.sweep() }.to raise_error(ArgumentError)
      end
    end
  end

end

