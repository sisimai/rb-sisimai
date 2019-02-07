require 'spec_helper'
require 'sisimai/address'
require 'sisimai/rfc5322'
require 'json'

describe Sisimai::Address do
  let(:addrobj) { Sisimai::Address.new(email) }

  emailaddrs = [
    { 'v' => '"Neko" <neko@example.jp>', 'a' => 'neko@example.jp', 'n' => 'Neko', 'c' => '' },
    { 'v' => '"=?ISO-2022-JP?B?dummy?=" <nyan@example.jp>',
      'a' => 'nyan@example.jp',
      'n' => '=?ISO-2022-JP?B?dummy?=',
      'c' => '', },
    { 'v' => '"N Y A N K O" <nyanko@example.jp>',
      'a' => 'nyanko@example.jp',
      'n' => 'N Y A N K O',
      'c' => '', },
    { 'v' => '"Shironeko Lui" <lui@example.jp>',
      'a' => 'lui@example.jp',
      'n' => 'Shironeko Lui',
      'c' => '', },
    { 'v' => '<aoi@example.jp>', 'a' => 'aoi@example.jp', 'n' => '', 'c' => '' },
    { 'v' => '<may@example.jp> may@example.jp', 'a' => 'may@example.jp', 'n' => 'may@example.jp', 'c' => '' },
    { 'v' => 'Odd-Eyes Aoki <aoki@example.jp>',
      'a' => 'aoki@example.jp',
      'n' => 'Odd-Eyes Aoki',
      'c' => '', },
    { 'v' => 'Mikeneko Shima <shima@example.jp> SHIMA@EXAMPLE.JP',
      'a' => 'shima@example.jp',
      'n' => 'Mikeneko Shima SHIMA@EXAMPLE.JP',
      'c' => '', },
    { 'v' => 'chosuke@neko <chosuke@example.jp>',
      'a' => 'chosuke@example.jp',
      'n' => 'chosuke@neko',
      'c' => '', },
    { 'v' => 'akari@chatora.neko <akari@example.jp>',
      'a' => 'akari@example.jp',
      'n' => 'akari@chatora.neko',
      'c' => '', },
    { 'v' => 'mari <mari@example.jp> mari@host.int',
      'a' => 'mari@example.jp',
      'n' => 'mari mari@host.int',
      'c' => '', },
    { 'v' => '8suke@example.gov (Mayuge-Neko)',
      'a' => '8suke@example.gov',
      'n' => '8suke@example.gov',
      'c' => '(Mayuge-Neko)', },
    { 'v' => 'Shibainu Hachibe. (Harima-no-kami) 8be@example.gov',
      'a' => '8be@example.gov',
      'n' => 'Shibainu Hachibe. 8be@example.gov',
      'c' => '(Harima-no-kami)', },
    { 'v' => 'neko(nyaan)chan@example.jp',
      'a' => 'nekochan@example.jp',
      'n' => 'nekochan@example.jp',
      'c' => '(nyaan)' },
    { 'v' => '(nyaan)neko@example.jp',
      'a' => 'neko@example.jp',
      'n' => 'neko@example.jp',
      'c' => '(nyaan)' },
    { 'v' => 'neko(nyaan)@example.jp',
      'a' => 'neko@example.jp',
      'n' => 'neko@example.jp',
      'c' => '(nyaan)' },
    { 'v' => 'nora(nyaan)neko@example.jp(cat)',
      'a' => 'noraneko@example.jp',
      'n' => 'noraneko@example.jp',
      'c' => '(nyaan) (cat)' },
    { 'v' => '<neko@example.com>:', 'a' => 'neko@example.com', 'n' => ':', 'c' => '' },
    { 'v' => '"<neko@example.org>"', 'a' => 'neko@example.org', 'n' => '', 'c' => '' },
    { 'v' => '"neko@example.net"',
      'a' => 'neko@example.net',
      'n' => 'neko@example.net',
      'c' => '' },
    { 'v' => %q|'neko@example.edu'|,
      'a' => 'neko@example.edu',
      'n' => %q|'neko@example.edu'|,
      'c' => '' },
    { 'v' => '`neko@example.cat`',
      'a' => 'neko@example.cat',
      'n' => '`neko@example.cat`',
      'c' => '' },
    { 'v' => '[neko@example.gov]',
      'a' => 'neko@example.gov',
      'n' => '[neko@example.gov]',
      'c' => '' },
    { 'v' => '{neko@example.int}',
      'a' => 'neko@example.int',
      'n' => '{neko@example.int}',
      'c' => '' },
    { 'v' => '"neko.."@example.jp',
      'a' => '"neko.."@example.jp',
      'n' => '"neko.."@example.jp',
      'c' => '' },
    { 'v' => 'Mail Delivery Subsystem <MAILER-DAEMON>',
      'a' => 'MAILER-DAEMON',
      'n' => 'Mail Delivery Subsystem',
      'c' => '', },
    { 'v' => 'postmaster', 'a' => 'postmaster', 'n' => 'postmaster', 'c' => '' },
    { 'v' => 'neko.nyaan@example.com',
      'a' => 'neko.nyaan@example.com',
      'n' => 'neko.nyaan@example.com',
      'c' => '' },
    { 'v' => 'neko.nyaan+nyan@example.com',
      'a' => 'neko.nyaan+nyan@example.com',
      'n' => 'neko.nyaan+nyan@example.com',
      'c' => '', },
    { 'v' => 'neko-nyaan@example.com',
      'a' => 'neko-nyaan@example.com',
      'n' => 'neko-nyaan@example.com',
      'c' => '' },
    { 'v' => 'neko-nyaan@example.com.',
      'a' => 'neko-nyaan@example.com.',
      'n' => 'neko-nyaan@example.com.',
      'c' => '' },
    { 'v' => 'n@example.com',
      'a' => 'n@example.com',
      'n' => 'n@example.com',
      'c' => '' },
#   { 'v' => '"neko.nyaan.@.nyaan.jp"@example.com',
#     'a' => '"neko.nyaan.@.nyaan.jp"@example.com',
#     'n' => '"neko.nyaan.@.nyaan.jp"@example.com',
#     'c' => '' },
    { 'v' => '"neko nyaan"@example.org',
      'a' => '"neko nyaan"@example.org',
      'n' => '"neko nyaan"@example.org',
      'c' => '' },
#   { 'v' => %q|"neko.(),:;<>[]\".NYAAN.\"neko@\\ \"neko\".nyaan"@neko.example.com|,
#     'a' => %q|"neko.(),:;<>[]\".NYAAN.\"neko@\\ \"neko\".nyaan"@neko.example.com|,
#     'n' => %q|"neko.(),:;<>[]\".NYAAN.\"neko@\\ \"neko\".nyaan"@neko.example.com|,
#     'c' => '' },
    { 'v' => %q|neko-nyaan@neko-nyaan.example.com|,
      'a' => 'neko-nyaan@neko-nyaan.example.com',
      'n' => 'neko-nyaan@neko-nyaan.example.com',
      'c' => '' },
    { 'v' => 'neko@nyaan', 'a' => 'neko@nyaan', 'n' => 'neko@nyaan', 'c' => '' },
    { 'v' => %q[#!$%&'*+-/=?^_`{}|~@example.org],
      'a' => %q[#!$%&'*+-/=?^_`{}|~@example.org],
      'n' => %q[#!$%&'*+-/=?^_`{}|~@example.org],
      'c' => '' },
#   { 'v' => %q*"()<>[]:,;@\\\"!#$%&'-/=?^_`{}| ~.a"@example.org*,
#     'a' => %q*"()<>[]:,;@\\\"!#$%&'-/=?^_`{}| ~.a"@example.org*,
#     'n' => %q*"()<>[]:,;@\\\"!#$%&'-/=?^_`{}| ~.a"@example.org*,
#     'c' => '' },
    { 'v' => %q|" "@example.org|,
      'a' => '" "@example.org',
      'n' => '" "@example.org',
      'c' => '' },
    { 'v' => %q|neko@localhost|,
      'a' => 'neko@localhost',
      'n' => 'neko@localhost',
      'c' => '' },
    { 'v' => 'neko@[IPv6:2001:DB8::1]',
      'a' => 'neko@[IPv6:2001:DB8::1]',
      'n' => 'neko@[IPv6:2001:DB8::1]',
      'c' => '' },
  ]
  isnotemail = [ '1', 'neko', 'cat%nyaan.jp', '' ]
  manyemails = [
    '"Neko, Nyaan" <(nora)neko@example.jp>, Nora Nyaans <neko(nora)nyaan@example.org>',
    'Neko (Nora, Nyaan) <neko@example.jp>, (Neko) "Nora, Mike" <neko@example.jp>',
  ]

  describe 'Class method' do
    describe '.new' do
      context 'valid email address' do
        let(:email) { 'maketest@libsisimai.org' }
        subject { addrobj }
        it 'is Sisimai::Address object' do
          is_expected.to be_a Sisimai::Address
        end
        it 'is valid method' do
          expect(addrobj.address).to be_a ::String
          expect(addrobj.host).to be_a ::String
          expect(addrobj.user).to be_a ::String
          expect(addrobj.verp).to be_a ::String
          expect(addrobj.alias).to be_a ::String
          expect(addrobj.name).to be_a ::String
          expect(addrobj.comment).to be_a ::String
        end
      end

      context '<MAILER-DAEMON>' do
        r = Sisimai::Address.new('Mail Delivery Subsystem <MAILER-DAEMON>')
        it 'returns Sisimai::Address object' do
          expect(r).to be_a Sisimai::Address
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

          it 'returns valid address in list' do
            expect(v).to be_a Array
            expect(v.size).to be == 1
            expect(v[0][:address]).not_to be nil
            expect(v[0][:address]).to be == e['a']
            expect(v[0][:comment]).to be_a ::String
            expect(v[0][:comment]).to be == e['c']
            expect(v[0][:name]).to be_a ::String
            expect(v[0][:name]).to be == e['n']
          end

          r = Sisimai::Address.find(e['v'], true)
          it 'returns valid address only in list' do
            expect(r).to be_a Array
            expect(r.size).to be == 1
            expect(r[0][:address]).not_to be nil
            expect(r[0][:address]).to be == e['a']
            expect(r[0].keys.size).to be == 1
          end
        end
      end

      context 'find many address' do
        manyemails.each do |e|
          r = Sisimai::Address.find(e)
          it 'returns list including multiple addresses' do
            expect(r).to be_a Array
            expect(r.size).to be == 2
          end

          r.each do |f|
            it('is a Hash') { expect(f).to be_a Hash }

            it 'includes a Sisimai::Address object' do
              a = Sisimai::Address.make(f)
              expect(a).to be_a Sisimai::Address

              expect(a.address).to be_a Object::String
              expect(a.comment).to be_a Object::String
              expect(a.name).to be_a Object::String

              expect(a.address.size).to be > 0
              expect(a.comment.size).to be > 0
              expect(a.name.size).to be > 0
            end
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

    describe '.make' do
      context 'valid email address' do
        emailaddrs.each do |e|
          a = []
          r = Sisimai::Address.make(Sisimai::Address.find(e['v']).shift)
          if cv = e['a'].match(/\A(.+)[@]([^@]+)\z/)
            a[0] = cv[1]
            a[1] = cv[2]
          end
          if Sisimai::RFC5322.is_mailerdaemon(e['v'])
            a[0] = e['a']
            a[1] = ''
          end

          it 'returns Sisimai::Address object' do
            expect(r).to be_a Sisimai::Address
            expect(r.address).to be == e['a']
            expect(r.user).to be == a[0]
            expect(r.host).to be == a[1]
            expect(r.verp).to be == ''
            expect(r.alias).to be == ''
            expect(r.name).to be == e['n']
            expect(r.comment).to be == e['c']
          end

          it 'writable accessor' do
            r.name = 'nyaan'
            r.comment = 'nyaan'
            expect(r.name).to be == 'nyaan'
            expect(r.comment).to be == 'nyaan'
          end
        end
      end

      context 'invalid email address' do
        isnotemail.each do |e|
          it 'returns nil' do
            expect(Sisimai::Address.make({ address: e })).to be nil
          end
        end
      end
    end

    describe '.s3s4' do
      context 'valid email address' do
        emailaddrs.each do |e|
          r = Sisimai::Address.s3s4(e['v'])
          it 'returns email address only' do
            expect(r).to be_a ::String
            expect(r).not_to be nil
            expect(r).to be == e['a']
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
      r = Sisimai::Address.new(e)
      q = Sisimai::Address.expand_verp(e)
      it 'returns expanded email address' do
        expect(q).to be == 'neko@example.jp'
        expect(e).to be == r.verp
      end
      it('returns nil') { expect(Sisimai::Address.expand_verp(nil)).to be_nil }
      it('returns nil') { expect(Sisimai::Address.expand_verp('2')).to be_nil }
    end

    describe '.alias' do
      e = 'neko+nyaa@example.jp'
      r = Sisimai::Address.new(e)
      q = Sisimai::Address.expand_alias(e)
      it 'returns expanded email address' do
        expect(q).to be == 'neko@example.jp'
        expect(e).to be == r.alias
      end
      it('returns nil') { expect(Sisimai::Address.expand_alias(nil)).to be_nil }
      it('returns nil') { expect(Sisimai::Address.expand_alias('2')).to be_nil }
    end

    describe '.undisclosed' do
      context 'valid argument character' do
        it 'returns dummy address' do
          expect(Sisimai::Address.undisclosed('r')).to be == 'undisclosed-recipient-in-headers@libsisimai.org.invalid'
          expect(Sisimai::Address.undisclosed('s')).to be == 'undisclosed-sender-in-headers@libsisimai.org.invalid'
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
      v = Sisimai::Address.new(e['v'])

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

      describe '#name' do
        subject { v.name }
        it 'returns a display name' do
          is_expected.to be_a String
          is_expected.to be == e['n']
        end
      end

      describe '#comment' do
        subject { v.comment }
        it 'returns a comment' do
          is_expected.to be_a String
          is_expected.to be == e['c']
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
