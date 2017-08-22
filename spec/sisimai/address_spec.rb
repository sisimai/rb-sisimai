require 'spec_helper'
require 'sisimai/address'
require 'sisimai/rfc5322'
require 'json'

describe Sisimai::Address do
  let(:addrobj) { Sisimai::Address.new(email) }

  emailaddrs = [
    { 'v' => %q|"Neko" <neko@example.jp>|, 'a' => 'neko@example.jp' },
    { 'v' => %q|"=?ISO-2022-JP?B?dummy?=" <nyan@example.jp>|, 'a' => 'nyan@example.jp' },
    { 'v' => %q|"N Y A N K O" <nyanko@example.jp>|, 'a' => 'nyanko@example.jp' },
    { 'v' => %q|"Shironeko Lui" <lui@example.jp>|, 'a' => 'lui@example.jp' },
    { 'v' => %q|<aoi@example.jp>|, 'a' => 'aoi@example.jp' },
    { 'v' => %q|<may@example.jp> may@example.jp|, 'a' => 'may@example.jp' },
    { 'v' => %q|Odd-Eyes Aoki <aoki@example.jp>|, 'a' => 'aoki@example.jp' },
    { 'v' => %q|Mikeneko Shima <shima@example.jp> SHIMA@EXAMPLE.JP|, 'a' => 'shima@example.jp' },
    { 'v' => %q|chosuke@neko <chosuke@example.jp>|, 'a' => 'chosuke@example.jp' },
    { 'v' => %q|akari@chatora.neko <akari@example.jp>|, 'a' => 'akari@example.jp' },
    { 'v' => %q|mari <mari@example.jp> mari@host.int|, 'a' => 'mari@example.jp' },
    { 'v' => %q|8suke@example.gov (Mayuge-Neko)|, 'a' => '8suke@example.gov' },
    { 'v' => %q|Shibainu Hachibe. (Harima-no-kami) 8be@example.gov|, 'a' => '8be@example.gov' },
    { 'v' => %q|nekochan@example.jp|, 'a' => 'nekochan@example.jp' },
    { 'v' => %q|<neko@example.com>:|, 'a' => 'neko@example.com' },
    { 'v' => %q|"<neko@example.org>"|, 'a' => 'neko@example.org' },
    { 'v' => %q|"neko@example.net"|, 'a' => 'neko@example.net' },
    { 'v' => %q|'neko@example.edu'|, 'a' => 'neko@example.edu' },
    { 'v' => %q|`neko@example.cat`|, 'a' => 'neko@example.cat' },
    { 'v' => %q|[neko@example.gov]|, 'a' => 'neko@example.gov' },
    { 'v' => %q|{neko@example.int}|, 'a' => 'neko@example.int' },
    { 'v' => %q|"neko.."@example.jp|, 'a' => '"neko.."@example.jp' },
    { 'v' => %q|Mail Delivery Subsystem <MAILER-DAEMON>|, 'a' => 'MAILER-DAEMON' },
    { 'v' => %q|postmaster|, 'a' => 'postmaster' },
    { 'v' => %q|neko.nyaan@example.com|, 'a' => 'neko.nyaan@example.com' },
    { 'v' => %q|neko.nyaan+nyan@example.com|, 'a' => 'neko.nyaan+nyan@example.com' },
    { 'v' => %q|neko-nyaan@example.com|, 'a' => 'neko-nyaan@example.com' },
    { 'v' => %q|neko-nyaan@example.com.|, 'a' => 'neko-nyaan@example.com.' },
    { 'v' => %q|n@example.com|, 'a' => 'n@example.com' },
#   { 'v' => %q|"neko.nyaan.@.nyaan.jp"@example.com|, 'a' => '"neko.nyaan.@.nyaan.jp"@example.com' },
#   { 'v' => %q|"neko.(),:;<>[]\".NYAAN.\"neko@\\ \"neko\".nyaan"@neko.example.com|,
#     'a' => %q|"neko.(),:;<>[]\".NYAAN.\"neko@\\ \"neko\".nyaan"@neko.example.com| },
#   { 'v' => %q|neko-nyaan@neko-nyaan.example.com|, 'a' => 'neko-nyaan@neko-nyaan.example.com' },
#   { 'v' => %q|neko@nyaan|, 'a' => 'neko@nyaan' },
#   { 'v' => q[#!$%&'*+-/=?^_`{}|~@example.org], 'a' => q[#!$%&'*+-/=?^_`{}|~@example.org] },
#   { 'v' => q*"()<>[]:,;@\\\"!#$%&'-/=?^_`{}| ~.a"@example.org*,
#     'a' => q*"()<>[]:,;@\\\"!#$%&'-/=?^_`{}| ~.a"@example.org* },
#   { 'v' => %q|" "@example.org|, 'a' => '" "@example.org' },
#   { 'v' => %q|neko@localhost|, 'a' => 'neko@localhost' },
#   { 'v' => %q|neko@[IPv6:2001:DB8::1]|, 'a' => 'neko@[IPv6:2001:DB8::1]' },
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

      context '<MAILER-DAEMON>' do
        v = Sisimai::Address.new('Mail Delivery Subsystem <MAILER-DAEMON>')
        it 'returns Sisimai::Address object' do
          expect(v).to be_a Sisimai::Address
        end
      end

      context 'wrong number of arguments' do
        it 'raises ArgumentError' do
          expect { Sisimai::Address.new }.to raise_error(ArgumentError)
          expect { Sisimai::Address.new(nil, nil) }.to raise_error(ArgumentError)
        end
      end
    end

    describe '.find' do
      context 'valid email address' do
        emailaddrs.each do |e|
          v = Sisimai::Address.find(e['v'])
          subject { v }
          it 'returns valid address in list' do
            is_expected.to be_a Array
            expect(v.size).to be == 1
            expect(v[0]['address']).not_to be nil
            expect(v[0]['address']).to be == e['a']
          end
        end
      end

      context 'invalid email address' do
        isnotemail.each do |e|
          it 'returns nil' do
            expect(Sisimai::Address.find(e)).to be nil
          end
        end
      end
    end

    describe '.parse' do
      context 'valid email address' do
        emailaddrs.each do |e|
          v = Sisimai::Address.parse([e['v']])
          subject { v }
          it 'returns valid address in list' do
            is_expected.to be_a Array
            expect(v.size).to be == 1
            expect(v[0]).not_to be nil
            expect(v[0]).to be == e['a']
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
        emailaddrs.each do |e|
          v = Sisimai::Address.s3s4(e['v'])
          subject { v }
          it 'returns email address only' do
            is_expected.to be_a String
            expect(v).not_to be nil
            expect(v).to be == e['a']
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
          expect(Sisimai::Address.undisclosed(:r)).to be == 'undisclosed-recipient-in-headers@libsisimai.org.invalid'
          expect(Sisimai::Address.undisclosed(:s)).to be == 'undisclosed-sender-in-headers@libsisimai.org.invalid'
        end
        it 'returns nil' do
          expect(Sisimai::Address.undisclosed(nil)).to be nil
        end
      end
    end
  end

  describe 'Instance method' do
    emailaddrs.each do |e|
      a = Sisimai::Address.s3s4(e['v']).split('@')
      v = Sisimai::Address.new(Sisimai::Address.s3s4(e['v']))

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
          if Sisimai::RFC5322.is_mailerdaemon(e['v'])
            is_expected.to be_empty
          else
            is_expected.to be == a[1]
          end
        end
      end

      describe '#address' do
        subject { v.address }
        it 'returns whole email address' do
          is_expected.to be_a String
          is_expected.to be == a[0] + '@' + a[1] unless Sisimai::RFC5322.is_mailerdaemon(e['v'])
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

      describe '#to_s' do
        it 'returns address' do
          expect(v.to_s).to be_a String
          expect(v.to_s).to be v.address
        end
      end
    end
  end

end
