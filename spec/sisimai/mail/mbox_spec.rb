require 'spec_helper'
require 'sisimai/mail/mbox'

describe Sisimai::Mail::Mbox do
  samplemailbox = './set-of-emails/mailbox/mbox-0'
  let(:mailobj) { Sisimai::Mail::Mbox.new(samples) }
  let(:mockobj) { Sisimai::Mail::Mbox.new(invalid) }

  describe 'class method' do
    describe '.new' do
      context 'mbox file exists' do
        let(:samples) { samplemailbox }
        subject { mailobj }
        it 'returns Sisimai::Mail::Mbox object' do
          is_expected.to be_a Sisimai::Mail::Mbox
        end
      end

      context 'mbox file does not exist' do
        let(:invalid) { '/etc/neko/nyan' }
        it 'raises Errno::ENOENT' do
          expect { mockobj }.to raise_error(Errno::ENOENT)
        end
      end

      context 'argument is not a file' do
        let(:invalid) { '/etc/' }
        it 'raises RuntimeError' do
          expect { mockobj }.to raise_error(RuntimeError)
        end
      end

      context 'wrong number of arguments' do
        it 'raises ArgumentError' do
          expect { Sisimai::Mail::Mbox.new }.to raise_error(ArgumentError)
          expect { Sisimai::Mail::Mbox.new(nil, nil) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe 'instance method' do
    let(:samples) { samplemailbox }
    before do
      mailobj.read
    end
    describe '#dir' do
      subject { mailobj.dir }
      it 'includes ./set-of-emails' do
        is_expected.to be_a String
        is_expected.to match(%r|/set-of-emails|)
      end
    end
    describe '#path' do
      subject { mailobj.path }
      it 'returns path' do
        is_expected.to be_a String
        is_expected.to be == samples
      end
    end
    describe '#file' do
      subject { mailobj.file }
      it 'returns filename' do
        is_expected.to be_a String
        is_expected.to be == File.basename(samples)
      end
    end
    describe '#size' do
      subject { mailobj.size }
      it 'returns mbox size' do
        is_expected.to be_a Integer
        is_expected.to be == 96906
      end
    end
    describe '#handle' do
      let(:handle) { mailobj.handle }
      subject { handle }
      it 'is valid IO::File object' do
        is_expected.to be_a File
        expect(handle.closed?).to be false
        expect(handle.stat.readable?).to be true
        expect(handle.stat.size).to be > 0
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
      mailbox = Sisimai::Mail::Mbox.new(samplemailbox)
      emindex = 0
      hasread = 0

      while r = mailbox.read do
        emindex += 1
        mailtxt  = r
        hasread += mailtxt.size
        subject { mailtxt }

        it "is #{mailbox.file} ##{emindex}" do
          expect(mailbox.file).to be == File.basename(samplemailbox)
        end
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

