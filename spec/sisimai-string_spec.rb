require 'spec_helper'
require 'sisimai/string'

describe 'Sisimai::String' do
  describe 'Sisimai::String.token() method' do
    s = 'envelope-sender@example.jp';
    r = 'envelope-recipient@example.org';
    t = '239aa35547613b2fa94f40c7f35f4394e99fdd88';

    it 'token(' + s + ',' + r + ',1) generates a token string' do
      expect(Sisimai::String.token(s,r,1)).to be_true
    end

    it 'token(' + s + ',' + r + ',1) returns token: ' + t do
      expect(Sisimai::String.token(s,r,1)).to eq t
    end

    it 'token(' + s + ',' + r + ',0) generates a token string' do
      expect(Sisimai::String.token(s,r,0)).to be_true
    end

    context 'Errors from the method' do
      it 'token(nil) raise an error: ArgumentError' do
        expect { Sisimai::String.token(nil) }.to raise_error(ArgumentError)
      end

      it 'token(' + s + ') raise an error: ArgumentError' do
        expect { Sisimai::String.token(s) }.to raise_error(ArgumentError)
      end

      it 'token(' + s + ',' + r + ') raise an error: ArgumentError' do
        expect { Sisimai::String.token(s,r) }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'Sisimai::String.is_8bit() method' do
    it 'is_8bit(8) returns 8' do
      expect(Sisimai::String.is_8bit(8)).to eq 8
    end

    it 'is_8bit(neko) returns false' do
      expect(Sisimai::String.is_8bit('neko')).to be_false

    end
    it 'is_8bit(日本語) returns true' do
      expect(Sisimai::String.is_8bit('日本語')).to be_true
    end

    context 'Errors from the method' do
      it 'is_8bit() raise an error: ArgumentError' do
        expect { Sisimai::String.is_8bit() }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'Sisimai::String.sweep() method' do
    it 'sweep(nil) returns nil' do
      expect(Sisimai::String.sweep(nil)).to be_nil
    end

    it 'sweep(" neko cat ") returns "neko cat"' do
      expect(Sisimai::String.sweep(' neko cat ')).to eq 'neko cat'
    end

    it 'sweep(" nyaa   !!") returns "nyaa !!"' do
      expect(Sisimai::String.sweep(' nyaa   !!')).to eq 'nyaa !!'
    end

    context 'Errors from the method' do
      it 'sweep() raise an error: ArgumentError' do
        expect { Sisimai::String.sweep() }.to raise_error(ArgumentError)
      end
    end
  end

end

