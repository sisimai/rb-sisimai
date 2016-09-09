require 'spec_helper'
require 'sisimai/string'

describe Sisimai::String do
  describe '.EOM' do
    v = '__END_OF_EMAIL_MESSAGE__'
    it('returns ' + v) { expect(Sisimai::String.EOM()).to eq v }
  end

  describe '.token' do
    s = 'envelope-sender@example.jp'
    r = 'envelope-recipient@example.org'
    t = '239aa35547613b2fa94f40c7f35f4394e99fdd88'

    context 'valid arguments' do
      it("returns #{t}") { expect(Sisimai::String.token(s,r,1)).to eq t }
      it('returns a token') { expect(Sisimai::String.token(s,r,0)).not_to be_empty }
      it('returns ""') { expect(Sisimai::String.token('', '', 0)).to be_empty }
      it("returns ''") { expect(Sisimai::String.token(s, '', 0)).to be_empty }
      it("returns ''") { expect(Sisimai::String.token('', r, 0)).to be_empty }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { Sisimai::String.token(nil) }.to raise_error(ArgumentError) }
      it('raises ArgumentError') { expect { Sisimai::String.token(s) }.to raise_error(ArgumentError) }
      it('raises ArgumentError') { expect { Sisimai::String.token(s, r) }.to raise_error(ArgumentError) }
    end
  end

  describe '.is_8bit' do
    context '7-bit string' do
      it('returns false') { expect(Sisimai::String.is_8bit(8)).to be false }
      it('returns false') { expect(Sisimai::String.is_8bit('neko')).to be false }
    end

    context 'empty string or nil' do
      it('returns nil') { expect(Sisimai::String.is_8bit(nil)).to be nil }
      it('returns nil') { expect(Sisimai::String.is_8bit('')).to be nil }
    end

    context '8-bit Strings' do
      it('returns true') { expect(Sisimai::String.is_8bit('八')).to be true }
      it('returns true') { expect(Sisimai::String.is_8bit('猫')).to be true }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { Sisimai::String.is_8bit }.to raise_error(ArgumentError) }
      it('raises ArgumentError') { expect { Sisimai::String.is_8bit('x', 'y') }.to raise_error(ArgumentError) }
    end
  end

  describe '.sweep' do
    context 'valid string or nil' do
      it('returns "neko cat"') { expect(Sisimai::String.sweep(' neko cat ')).to eq 'neko cat' }
      it('returns "nyaa !!"') { expect(Sisimai::String.sweep(' nyaa   !!')).to eq 'nyaa !!' }
      it('returns nil') { expect(Sisimai::String.sweep(nil)).to be nil }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { Sisimai::String.sweep }.to raise_error(ArgumentError) }
      it('raises ArgumentError') { expect { Sisimai::String.sweep('x', 'y') }.to raise_error(ArgumentError) }
    end
  end

  describe '.to_plain' do
    xhtml = '
        <html>
        <head>
        </head>
        <body>
            <h1>neko</h1>
            <div>
            <a href = "http://libsisimai.org">Sisimai</a>
            <a href = "mailto:maketest@libsisimai.org">maketest</a>
            </div>
        </body>
        </html>
    '
    parts = '<body>Nyaan</body>'

    context 'valid string' do
      it('returns String') { expect(Sisimai::String.to_plain(xhtml)).to be_a String }
      it('has the size')   { expect(Sisimai::String.to_plain(xhtml).size).to be > 0 }
      it('returns "neko"') { expect(Sisimai::String.to_plain(xhtml)).to match(/\bneko\b/) }
      it('is not include HTML tags') { 
        expect(Sisimai::String.to_plain(xhtml)).not_to match(/<html>/)
        expect(Sisimai::String.to_plain(xhtml)).not_to match(/<head>/)
        expect(Sisimai::String.to_plain(xhtml)).not_to match(/<body>/)
        expect(Sisimai::String.to_plain(xhtml)).not_to match(/<div>/)
        expect(Sisimai::String.to_plain(xhtml)).to match(/\[Sisimai\]/)
        expect(Sisimai::String.to_plain(xhtml)).to match(/\[maketest\]/)
        expect(Sisimai::String.to_plain(xhtml)).to match(%r|\(http://.+\)|)
        expect(Sisimai::String.to_plain(xhtml)).to match(%r|\(mailto:.+\)|)
      }

      it('returns plain text') {
        expect(Sisimai::String.to_plain(parts, true)).to match(/Nyaan/)
        expect(Sisimai::String.to_plain(parts, true)).not_to match(/<body>/)
      }

      it('does not returns plain text') {
        expect(Sisimai::String.to_plain(parts, false)).to match(/Nyaan/)
        expect(Sisimai::String.to_plain(parts, false)).to match(/<body>/)
      }
    end

    context 'wrong number of arguments' do
      it('raises ArgumentError') { expect { Sisimai::String.to_plain(nil, nil, nil) }.to raise_error(ArgumentError) }
    end
  end
end
