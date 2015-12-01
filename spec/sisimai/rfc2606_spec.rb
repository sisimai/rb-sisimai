require 'spec_helper'
require 'sisimai/rfc2606'

describe 'Sisimai::RFC2606' do
  cn = Sisimai::RFC2606
  arerfc2606 = ['example.jp', 'example.com', 'example.org', 'example.net']
  notrfc2606 = ['bouncehammer.jp', 'cubicroot.jp', 'gmail.com', 'me.com']

  describe '.is_reserved' do
    describe 'Valid Domain String' do
      arerfc2606.each do |e|
        context "(#{e})" do
          it('returns true') { expect(cn.is_reserved(e)).to be true }
        end
      end

      notrfc2606.each do |e|
        context "(#{e})" do
          it('returns false') { expect(cn.is_reserved(e)).to be false }
        end
      end
    end

    describe 'Valid Email Address String' do
      arerfc2606.each do |e|
        context "(neko@#{e})" do
          it('returns true') { expect(cn.is_reserved('neko@' + e)).to be true }
        end
      end

      notrfc2606.each do |e|
        context "(example.jp@#{e})" do
          it('returns false') { expect(cn.is_reserved('example.jp@' + e)).to be false }
        end
      end
    end

    describe 'Not String' do
      context '(2)' do
        it('returns false') { expect(cn.is_reserved(2)).to be false }
      end
      context '(nil)' do
        it('returns false') { expect(cn.is_reserved(nil)).to be false }
      end
    end

    describe 'Wrong Number of Arguments' do
      context '("x","y")' do
        it('raises ArgumentError') { expect { cn.is_reserved('x', 'y') }.to raise_error(ArgumentError) }
      end
    end

  end
end
