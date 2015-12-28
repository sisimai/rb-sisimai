require 'spec_helper'
require 'sisimai/mail/mbox'

describe Sisimai::Mail::Mbox do
  cn = Sisimai::Mail::Mbox
  sf = './set-of-emails/mailbox/mbox-0'
  let(:mailobj) { Sisimai::Mail::Mbox.new(samples) }
  let(:mockobj) { Sisimai::Mail::Mbox.new(invalid) }

  describe 'class method' do
    describe '.new' do
      context 'mbox file exists' do
        let(:samples) { sf }
        subject { mailobj }
        it("returns #{cn} object"){ is_expected.to be_a(cn) }
      end

      context 'mbox file does not exist' do
        let(:invalid) { '/etc/neko/nyan' }
        it('raises Errno::ENOENT') { expect { mockobj }.to raise_error(Errno::ENOENT) }
      end

      context 'argument is not a file' do
        let(:invalid) { '/etc/' }
        it('raises RuntimeError') { expect { mockobj }.to raise_error(RuntimeError) }
      end

      context 'wrong number of arguments' do
        it 'raises ArgumentError' do
          expect { cn.new }.to raise_error(ArgumentError)
        end
        it 'raises ArgumentError' do
          expect { cn.new(nil, nil) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe 'instance method' do
    let(:samples) { sf }
    before do
      mailobj.read
    end
    describe '#dir' do
      subject { mailobj.dir }
      it('returns String') { is_expected.to be_a(String) }
      it('includes ./set-of-emails')  { is_expected.to match(%r|/set-of-emails|) }
    end
    describe '#path' do
      subject { mailobj.path }
      it('returns String') { is_expected.to be_a(String) }
      it('returns path')   { is_expected.to be == samples }
    end
    describe '#file' do
      subject { mailobj.file }
      it('returns String')   { is_expected.to be_a(String) }
      it('returns filename') { is_expected.to be == File.basename(samples) }
    end
    describe '#size' do
      subject { mailobj.size }
      it('returns Integer') { is_expected.to be_a(Integer) }
      it('returns 96906')   { is_expected.to be == 96906 }
    end
    describe '#handle' do
      let(:handle) { mailobj.handle }
      subject { handle }
      it('is a IO::File') { is_expected.to be_a(File) }
      it('is not closed') { expect(handle.closed?).to be false }
      it('is readable')   { expect(handle.stat.readable?).to be true }
      it('has a size')    { expect(handle.stat.size).to be > 0 }
    end
    describe '#offset' do
      subject { mailobj.offset }
      it('returns Integer') { is_expected.to be_a(Integer) }
      it('is larger than 0') { is_expected.to be > 0 }
      it('is smaller than size') { is_expected.to be < mailobj.size }
    end

    describe '#read' do
      mailbox = Sisimai::Mail::Mbox.new(sf)
      emindex = 0
      hasread = 0

      while r = mailbox.read do
        emindex += 1
        mailtxt  = r
        hasread += mailtxt.size
        subject { mailtxt }

        it "is reading #{mailbox.file} ##{emindex}" do
          expect(mailbox.file).to be == File.basename(sf)
        end
        it('returns String') { is_expected.to be_a(String) }
        it('matches /From:/'){ is_expected.to match(/From:\s*/) }
        it "is #{mailtxt.size} bytes file" do
          expect(mailtxt.size).to be > 0
        end
        example "current position is #{mailbox.offset}" do
          expect(mailbox.offset).to be == hasread + 512
        end
      end

      example "the number of emails is #{emindex}" do
        expect(emindex).to be == 37
      end
      example "loaded size is #{hasread}" do
        expect(hasread).to be == mailbox.size - 512
      end
    end

  end
end

