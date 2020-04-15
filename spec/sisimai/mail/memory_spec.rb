require 'spec_helper'
require 'sisimai/mail/memory'

describe Sisimai::Mail::Memory do
  samplemailbox = [
    './set-of-emails/mailbox/mbox-0',
    './set-of-emails/maildir/bsd/lhost-sendmail-01.eml'
  ]
  let(:mailobj) { Sisimai::Mail::Memory.new(samples) }
  let(:mockobj) { Sisimai::Mail::Memory.new(invalid) }
  emailcontents = nil

  describe 'class method' do
    describe '.new' do
      context 'mbox file exists' do
        messagehandle = File.open(samplemailbox[0], 'r')
        emailcontents = messagehandle.read
        messagehandle.close
        let(:samples) { emailcontents }
        subject { mailobj }
        it 'returns Sisimai::Mail::Memory object' do
          is_expected.to be_a Sisimai::Mail::Memory
        end
      end

      context 'argument is not a String' do
        let(:invalid) { 1 }
        it 'raises RuntimeError' do
          expect { mockobj }.to raise_error(RuntimeError)
        end
      end

      context 'argument is empty' do
        let(:invalid) { '' }
        it 'raises RuntimeError' do
          expect { mockobj }.to raise_error(RuntimeError)
        end
      end

      context 'wrong number of arguments' do
        it 'raises ArgumentError' do
          expect { Sisimai::Mail::Memory.new }.to raise_error(ArgumentError)
          expect { Sisimai::Mail::Memory.new(nil, nil) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe 'instance method' do
    samplemailbox.each do |b|
      messagehandle = File.open(samplemailbox[0], 'r')
      emailcontents = messagehandle.read
      messagehandle.close
      let(:samples) { emailcontents }
      before do
        mailobj.read
      end
      describe '#path' do
        subject { mailobj.path }
        it 'is "<MEMORY>"' do
          is_expected.to be_a ::String
          is_expected.to be == '<MEMORY>'
        end
      end
      describe '#size' do
        subject { mailobj.size }
        it 'returns email size' do
          is_expected.to be_a Integer
          is_expected.to be > 90000
        end
      end
      describe '#data' do
        subject { mailobj.data }
        it 'returns Array' do
          is_expected.to be_a Array
        end
      end
      describe '#offset' do
        subject { mailobj.offset }
        it 'returns valid offset size' do
          is_expected.to be_a Integer
          is_expected.to be > 0
          is_expected.to be < mailobj.size
        end
      end

      describe '#read' do
        mailbox = Sisimai::Mail::Memory.new(emailcontents)
        emindex = 0
        hasread = 0

        while r = mailbox.read do
          emindex += 1
          mailtxt  = r
          hasread += mailtxt.size
          subject { mailtxt }

          it 'returns valid email text' do
            is_expected.to be_a String
            is_expected.to match(/From:\s*/)
            expect(mailtxt.size).to be > 0
          end
          example 'current position is larger than 0' do
            expect(mailbox.offset).to be > 0
          end
        end

        example "the number of emails is #{emindex}" do
          expect(emindex).to be == 37
        end
        example 'loaded size is larger than 0' do
          expect(hasread).to be > 0
        end
      end
    end

  end
end

