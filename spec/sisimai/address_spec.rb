require 'spec_helper'
require 'sisimai/address'
require 'json'

describe Sisimai::Address do
  let(:addrobj) { Sisimai::Address.new(email) }

  emailaddrs = [
    'neko@example.jp', 'nyan@example.jp', 'nyanko@example.jp', 'lui@example.jp',
    'aoi@example.jp', 'may@example.jp', 'aoki@example.jp', 'shima@example.jp',
    'chosuke@example.jp', 'akari@example.jp', 'mari@example.jp', '8suke@example.gov',
    '8be@example.gov', 'nekochan@example.jp', 'neko@example.com', 'neko@example.org',
    'neko@example.net', 'neko@example.edu', 'neko@example.cat', 'neko@example.mil',
    'neko@example.gov', 'neko@example.int', 'neko@example.gl', '"neko.."@example.jp',
  ]
  emailfroms = [
    %q|"Neko" <neko@example.jp>|,
    %q|"=?ISO-2022-JP?B?dummy?=" <nyan@example.jp>|,
    %q|"N Y A N K O" <nyanko@example.jp>|,
    %q|"Shironeko Lui" <lui@example.jp>|,
    %q|<aoi@example.jp>|,
    %q|<may@example.jp> may@example.jp|,
    %q|Odd-Eyes Aoki <aoki@example.jp>|,
    %q|Mikeneko Shima <shima@example.jp> SHIMA@EXAMPLE.JP|,
    %q|chosuke@neko <chosuke@example.jp>|,
    %q|akari@chatora.neko <akari@example.jp>|,
    %q|mari <mari@example.jp> mari@host.int|,
    %q|8suke@example.gov (Mayuge-Neko)|,
    %q|Shibainu Hachibe. (Harima-no-kami) 8be@example.gov|,
    %q|nekochan@example.jp|,
    %q|<neko@example.com>:|,
    %q|"<neko@example.org>"|,
    %q|"neko@example.net"|,
    %q|'neko@example.edu'|,
    %q|`neko@example.cat`|,
    %q|(neko@example.mil)|,
    %q|[neko@example.gov]|,
    %q|{neko@example.int}|,
    %q|&lt;neko@example.gl&gt;|,
    %q|"neko.."@example.jp|,
  ]
  isnotemail = [ '1', 'neko', 'cat%nyaan.jp', '' ]

  describe 'Class method' do
    describe '.new' do
      context 'valid email address' do
        let(:email) { 'maketest@libsisimai.org' }
        subject { addrobj }
        it('is Sisimai::Address object') { is_expected.to be_a Sisimai::Address }
        it('has address method') { expect(addrobj.address).to be_a String }
        it('has host method') { expect(addrobj.host).to be_a String }
        it('has user method') { expect(addrobj.user).to be_a String }
        it('has verp method') { expect(addrobj.verp).to be nil }
        it('has alias method') { expect(addrobj.alias ).to be nil }
      end

      context 'wrong number of arguments' do
        it 'raises ArgumentError' do
          expect { Sisimai::Address.new }.to raise_error(ArgumentError)
        end
        it 'raises ArgumentError' do
          expect { Sisimai::Address.new(nil, nil) }.to raise_error(ArgumentError)
        end
      end
    end

    describe '.parse' do
      context 'valid email address' do
        emailfroms.each do |e|
          v = Sisimai::Address.parse([e])
          subject { v }
          it('returns Array') { is_expected.to be_a Array }
          it('has 1 element: ' + e) { expect(v.size).to be == 1 }
          it('returns ' + v[0]) { expect(emailaddrs.index(v[0])).not_to be nil }
        end
      end

      context 'invalid email address' do
        isnotemail.each do |e|
          it('returns nil') { expect(Sisimai::Address.parse([e])).to be nil }
        end
      end
    end

    describe '.s3s4' do
      context 'valid email address' do
        emailfroms.each do |e|
          v = Sisimai::Address.s3s4(e)
          subject { v }
          it('returns String') { is_expected.to be_a String }
          it('returns ' + v) { expect(emailaddrs.index(v)).not_to be nil }
        end
      end
      context 'invalid email address' do
        isnotemail.each do |e|
          it('returns ' + e.to_s) { expect(Sisimai::Address.s3s4(e)).to be == e }
        end
      end
    end

    describe '.expand_verp' do
      e = 'nyaa+neko=example.jp@example.org'
      v = Sisimai::Address.new(e)
      r = Sisimai::Address.expand_verp(e)
      example('.expand_verp returns ' + r ) { expect(r).to be == v.address }
      example('.verp returns ' + e ) { expect(e).to be == v.verp }
    end

    describe '.alias' do
      e = 'neko+nyaa@example.jp'
      v = Sisimai::Address.new(e)
      r = Sisimai::Address.expand_alias(e)
      example('.expand_alias returns ' + r ) { expect(r).to be == v.address }
      example('.alias returns ' + e ) { expect(e).to be == v.alias }
    end

    describe '.undisclosed' do
      context 'valid argument character' do
        it 'returns dummy recipient address' do
          expect(Sisimai::Address.undisclosed('r')).to be == 'undisclosed-recipient-in-headers@dummy-domain.invalid'
        end
        it 'returns dummy addresser address' do
          expect(Sisimai::Address.undisclosed('s')).to be == 'undisclosed-sender-in-headers@dummy-domain.invalid'
        end
        it('returns nil') { expect(Sisimai::Address.undisclosed(nil)).to be nil }
      end
    end
  end

  describe 'Instance method' do
    emailfroms.each do |e|
      a = Sisimai::Address.s3s4(e).split('@')
      v = Sisimai::Address.new(Sisimai::Address.s3s4(e))

      it('is Sisimai::Address object') { expect(v).to be_a Sisimai::Address }
      example('#user returns ' + a[0] ) { expect(v.user).to be == a[0] }
      example('#host returns ' + a[1] ) { expect(v.host).to be == a[1] }
      example '#address returns ' + v.address do
        expect(emailaddrs.index(v.address)).not_to be nil
      end
      example('#verp returns nil') { expect(v.verp).to be nil }
      example('#alias returns nil') { expect(v.alias).to be nil }

      example('#to_json returns String') { expect(v.to_json).to be_a String }
      example('#to_json returns address') { expect(v.to_json).to be v.address }
    end
  end

end
