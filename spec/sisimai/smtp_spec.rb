require 'spec_helper'
require 'sisimai/smtp'

describe Sisimai::SMTP do
  cn = Sisimai::SMTP
  rv = cn.command

  describe '.command' do
    context 'No arguments' do
      it('returns Hash') { expect(rv).to be_a Hash }
      %w|helo mail rcpt data|.each do |e|
        it('Key "' + e + '" exists') { expect(rv.key?(e.to_sym)).to be true }
        it(e + 'is Regexp object')   { expect(rv[e.to_sym]).to be_a Regexp }
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { cn.command(nil) }.to raise_error(ArgumentError)
        expect { cn.command(nil, nil) }.to raise_error(ArgumentError)
      end
    end
  end

end

