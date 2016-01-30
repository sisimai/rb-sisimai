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
        it 'is Sisimai::Address object' do
          is_expected.to be_a Sisimai::Address
        end
        it 'is valid method' do
          expect(addrobj.address).to be_a String
          expect(addrobj.host).to be_a String
          expect(addrobj.user).to be_a String
          expect(addrobj.verp).to be_a String
          expect(addrobj.alias ).to be_a String
        end
      end

      context 'wrong number of arguments' do
        it 'raises ArgumentError' do
          expect { Sisimai::Address.new }.to raise_error(ArgumentError)
          expect { Sisimai::Address.new(nil, nil) }.to raise_error(ArgumentError)
        end
      end
    end

    describe '.parse' do
      context 'valid email address' do
        emailfroms.each do |e|
          v = Sisimai::Address.parse([e])
          subject { v }
          it 'returns valid address in list' do
            is_expected.to be_a Array
            expect(v.size).to be == 1
            expect(emailaddrs.index(v[0])).not_to be nil
          end
        end
      end

      context 'invalid email address' do
        isnotemail.each do |e|
          it 'returns nil' do
            expect(Sisimai::Address.parse([e])).to be nil
          end
        end
      end
    end

    describe '.s3s4' do
      context 'valid email address' do
        emailfroms.each do |e|
          v = Sisimai::Address.s3s4(e)
          subject { v }
          it 'returns email address only' do
            is_expected.to be_a String
            expect(emailaddrs.index(v)).not_to be nil
          end
        end
      end
      context 'invalid email address' do
        isnotemail.each do |e|
          it 'returns ' + e.to_s do
            expect(Sisimai::Address.s3s4(e)).to be == e
          end
        end
      end
    end

    describe '.expand_verp' do
      e = 'nyaa+neko=example.jp@example.org'
      v = Sisimai::Address.new(e)
      r = Sisimai::Address.expand_verp(e)
      it 'returns expanded email address' do
        expect(r).to be == v.address
        expect(e).to be == v.verp
      end
    end

    describe '.alias' do
      e = 'neko+nyaa@example.jp'
      v = Sisimai::Address.new(e)
      r = Sisimai::Address.expand_alias(e)
      it 'returns expanded email address' do
        expect(r).to be == v.address
        expect(e).to be == v.alias
      end
    end

    describe '.undisclosed' do
      context 'valid argument character' do
        it 'returns dummy address' do
          expect(Sisimai::Address.undisclosed('r')).to be == 'undisclosed-recipient-in-headers@dummy-domain.invalid'
          expect(Sisimai::Address.undisclosed('s')).to be == 'undisclosed-sender-in-headers@dummy-domain.invalid'
        end
        it 'returns nil' do
          expect(Sisimai::Address.undisclosed(nil)).to be nil
        end
      end
    end
  end

  describe 'Instance method' do
    emailfroms.each do |e|
      a = Sisimai::Address.s3s4(e).split('@')
      v = Sisimai::Address.new(Sisimai::Address.s3s4(e))

      it 'is Sisimai::Address object' do
        expect(v).to be_a Sisimai::Address
      end

      describe '#user' do
        subject { v.user }
        it 'returns local part' do
          is_expected.to be_a String
          is_expected.to be == a[0]
        end
      end
      describe '#host' do
        subject { v.host }
        it 'returns domain part' do
          is_expected.to be_a String
          is_expected.to be == a[1]
        end
      end

      describe '#address' do
        subject { v.address }
        it 'returns whole email address' do
          is_expected.to be_a String
          is_expected.to be == a[0] + '@' + a[1]
          expect(emailaddrs.index(v.address)).not_to be nil
        end
      end

      describe '#verp' do
        it 'returns empty String' do
          expect(v.verp).to be_a String
          expect(v.verp).to be_empty
        end
      end

      describe '#alias' do
        it 'returns empty String' do
          expect(v.alias).to be_a String
          expect(v.alias).to be_empty
        end
      end

      describe '#to_json' do
        it 'returns address' do
          expect(v.to_json).to be_a String
          expect(v.to_json).to be v.address
        end
      end
    end
  end

end
