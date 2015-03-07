require 'spec_helper'
require 'sisimai/string'

describe 'Sisimai::String' do
  describe 'Sisimai::String.token() methods' do
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
end

