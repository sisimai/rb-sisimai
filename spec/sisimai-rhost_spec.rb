require 'spec_helper'
require 'sisimai/rhost'

describe Sisimai::Rhost do
  cn = Sisimai::Rhost
  describe '.list' do
    context '()' do
      v = cn.list
      it 'returns Array' do
        expect(v.kind_of?(Array)).to be true
      end
      v.each do |e|
        describe e do
          it('is a String')       { expect(e.kind_of?(String)).to be true }
          it('is valid hostname') { expect(e).to match(/\A[-.a-z0-9]+\z/) }
        end
      end
    end

    describe 'Wrong Number of Arguments' do
      context '(nil)' do
        it('raises ArgumentError') { expect { cn.list(nil) }.to raise_error(ArgumentError) }
      end
      context '(nil,nil)' do
        it('raises ArgumentError') { expect { cn.list(nil, nil) }.to raise_error(ArgumentError) }
      end
    end
  end

  describe '.match' do
    describe 'Valid Argument String' do
      v = ['aspmx.l.google.com']
      v.each do |e|
        context "(#{e})" do
          it('returns true') { expect(cn.match(e)).to be true }
        end
      end
      context 'example.jp' do
        it('returns false') { expect(cn.match('example.jp')).to be false }
      end
    end

    describe 'Wrong Number of Arguments' do
      context '(nil,nil)' do
        it('raises ArgumentError') { expect { cn.match(nil, nil) }.to raise_error(ArgumentError) }
      end
    end
  end

  describe 'get' do
    v = nil
    context '(nil)' do
      it 'returns reason text' do
        pending 'Tests will be added after implementation of Sisimai::Data class'
        expect(cn.get(v)).not_to be nil
      end
    end
  end
end

