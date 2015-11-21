require 'spec_helper'
require 'sisimai/rfc3463'

describe 'Sisimai::RFC3463' do
  cn = Sisimai::RFC3463
  standards = cn.standardcode
  internals = cn.internalcode

  describe '.standardcode' do
    it('returns Hash') { expect(standards).to be_a(Hash) }
    standards.each_key do |e|
      context "[#{e}]" do
        it('includes Hash') { expect(standards[e]).to be_a(Hash) }
      end
      standards[e].each_key do |f|
        context "[#{f}]" do
          it('includes Array') { expect(standards[e][f]).to be_a(Array) }
          standards[e][f].each do |g|
            example("#{g} match with DSN pattern") { expect(g).to match(/\A[45][.]\d[.]\d\z/) }
          end
        end
      end
    end
  end

  describe '.internalcode' do
    it('returns Hash') { expect(internals).to be_a(Hash) }
    internals.each_key do |e|
      context "[#{e}]" do
        it('includes Hash') { expect(internals[e]).to be_a(Hash) }
      end
      internals[e].each_key do |f|
        context "[#{f}]" do
          it('includes Array') { expect(internals[e][f]).to be_a(Array) }
          internals[e][f].each do |g|
            example("#{g} match with DSN pattern") { expect(g).to match(/\A[45][.]\d[.]\d{3}\z/) }
          end
        end
      end
    end
  end

  describe '.status' do
    describe 'Valid Reason String' do
      %w[permanent temporary].each do |e|
        b = e[0, 1]

        standards[e].each_key do |f|
          v = cn.status(f, b, 's')
          context "(#{f}, #{b}, s)" do
            it('returns DSN value: ' + v) { expect(v).to match(/\A[45][.]\d[.]\d/) }
          end
        end

        internals[e].each_key do |f|
          v = cn.status(f, b, 'i')
          context "(#{f}, #{b}, i)" do
            it('returns DSN value: ' + v) { expect(v).to match(/\A[45][.]\d[.]\d+/) }
          end
        end
      end
    end

    describe 'Invalid Reason String' do
      context '("neko","p","s")' do
        it('returns ""') { expect(cn.status('neko', 'p', 's')).to be_empty }
      end
      context '(nil,"p","s")' do
        it('returns ""') { expect(cn.status(nil, 'p', 's')).to be_empty }
      end
      context '(0,"p","s")' do
        it('returns ""') { expect(cn.status(0, 'p', 's')).to be_empty }
      end
    end

    describe 'First Argument Only' do
      context '("expired")' do
        it('returns "5.X.X"') { expect(cn.status('expired')).to match(/\A5[.]\d+[.]\d+\z/) }
      end
    end

    describe 'Invalid Type String' do
      context '("mailboxfull","x","s")' do
        it('returns "5.X.X"') { expect(cn.status('mailboxfull', 'x', 's')).to match(/\A5[.]\d[.]\d\z/) }
      end
      context '("mailboxfull","p","x")' do
        it('returns "5.X.X"') { expect(cn.status('mailboxfull', 'p', 'x')).to match(/\A5[.]\d[.]\d\z/) }
      end
    end

    describe 'Wrong Number of Arguments' do
      context '("w","x","y","z")' do
        it('raises ArgumentError') { expect { cn.status('w', 'x', 'y', 'z') }.to raise_error(ArgumentError) }
      end
    end
  end

  describe '.reason' do
    describe 'Valid DSN Value String' do
      %w[permanent temporary].each do |e|
        standards[e].each_key do |f|
          standards[e][f].each do |g|
            v = cn.reason(g)
            context "(#{g})" do
              it('returns ' + v) { expect(cn.reason(g)).to be == v }
            end
          end
        end

        internals[e].each_key do |f|
          internals[e][f].each do |g|
            v = cn.reason(g)
            context "(#{g})" do
              it('returns ' + v) { expect(cn.reason(g)).to be == v }
            end
          end
        end
      end
    end

    describe 'Invalid Value String' do
      context '("neko")' do
        it('returns ""') { expect(cn.reason('neko')).to be_empty }
      end
      context '(nil)' do
        it('returns ""') { expect(cn.reason(nil)).to be_empty }
      end
      context '(0)' do
        it('returns ""') { expect(cn.reason(0)).to be_empty }
      end
      context '()' do
        it('returns ""') { expect(cn.reason).to be_empty }
      end
    end

    describe 'Wrong Number of Arguments' do
      context '("x","y")' do
        it('raises ArgumentError') { expect { cn.reason('x', 'y') }.to raise_error(ArgumentError) }
      end
    end
  end

  diagnosis = [
    %q|SMTP; 450 4.7.1 Access denied. IP name lookup failed [192.0.2.222]|,
    %q|SMTP; 550 5.1.1 Requested action not taken: mailbox unavailable|,
    %q|SMTP; 550 5.6.9 improper use of 8-bit data in message header|,
    %q|SMTP; 552-5.7.0 This message was blocked because its content presents a potential|,
    %q|smtp; 5.1.0 - Unknown address error 550-'5.2.2 <kijitora@example.jp>... Mailbox Full' (delivery attempts: 0)|,
    %q|smtp; 5.4.7 - Delivery expired (message too old) 'timeout' (delivery attempts: 0)|,
    %q|smtp;550 5.2.2 <mikeneko@example.co.jp>... Mailbox Full|,
  ]

  describe '.getdsn' do
    describe 'Valid String Including DSN Value' do
      diagnosis.each do |e|
        context "(#{e[0, 40]}...)" do
          v = cn.getdsn(e)
          it('returns ' + v) { expect(v).to match(/\A[45][.]\d[.]\d\z/) }
        end
      end
    end

    describe 'Valid String Including No DSN' do
      context '("neko")' do
        it('returns ""') { expect(cn.getdsn('neko')).to be_empty }
      end
      context '(nil)' do
        it('returns ""') { expect(cn.getdsn(nil)).to be_empty }
      end
      context '()' do
        it('returns ""') { expect(cn.getdsn).to be_empty }
      end
    end

    describe 'Wrong Number of Arguments' do
      context '("x","y")' do
        it('raises ArgumentError') { expect { cn.getdsn('x', 'y') }.to raise_error(ArgumentError) }
      end
    end
  end

  describe '.is_softbounce' do
    describe 'Valid String Including DSN Value' do
      diagnosis.each do |e|
        context "(#{e[0, 40]}...)" do
          r = cn.getdsn(e)
          if r[0, 1].to_i == 4
            it('returns true')  { expect(cn.is_softbounce(e)).to be true }
          elsif r[0, 1].to_i == 5
            it('returns false') { expect(cn.is_softbounce(e)).to be false }
          end
        end
      end
    end

    describe 'Valid String Including No DSN' do
      context '("neko")' do
        it('returns nil') { expect(cn.is_softbounce('neko')).to be nil }
      end
      context '(nil)' do
        it('returns nil') { expect(cn.is_softbounce(nil)).to be nil }
      end
      context '()' do
        it('returns nil') { expect(cn.is_softbounce).to be nil }
      end
    end

    describe 'Wrong Number of Arguments' do
      context '("x","y")' do
        it('raises ArgumentError') { expect { cn.is_softbounce('x', 'y') }.to raise_error(ArgumentError) }
      end
    end
  end
end
