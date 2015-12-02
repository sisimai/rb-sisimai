require 'spec_helper'
require 'sisimai/smtp'

describe Sisimai::SMTP do
  cn = Sisimai::SMTP
  let(:rv) { cn.is_softbounce(se) }

  describe '.is_softbounce' do
    context 'reply code is 4XX' do
      let(:se) { '450 4.7.1 Client host rejected' }
      subject { rv }
      it('returns True') { is_expected.to be true }
      it('returns True') { expect(cn.is_softbounce(421)).to be true }
    end

    context 'reply code is 5XX' do
      let(:se) { '553 5.3.5 system config error' }
      subject { rv }
      it('returns False') { is_expected.to be false }
    end

    context 'reply code is neither 4xx nor 5xx' do
      let(:se) { '250 OK' }
      subject { rv }
      it('returns nil') { is_expected.to be nil }
      it('returns nil') { expect(cn.is_softbounce).to be nil }
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { cn.is_softbounce(nil, nil) }.to raise_error(ArgumentError)
      end
    end

  end
end

