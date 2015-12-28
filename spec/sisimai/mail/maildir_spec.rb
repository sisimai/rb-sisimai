require 'spec_helper'
require 'sisimai/mail/maildir'

describe Sisimai::Mail::Maildir do
  cn = Sisimai::Mail::Maildir
  sf = './set-of-emails/maildir/bsd'
  let(:mailobj) { cn.new(samples) }
  let(:mockobj) { cn.new(invalid) }

  describe 'class method' do
    describe '.new' do
      context 'Maildir/ exists' do
        let(:samples) { sf }
        subject { mailobj }
        it("returns #{cn} object") { is_expected.to be_a(cn) }
        it('returns String') { expect(mailobj.read).to be_a(String) }
      end

      context 'directory does not exist' do
        let(:invalid) { '/etc/neko/nyan' }
        it('raises Errno::ENOENT') { expect { mockobj }.to raise_error(Errno::ENOENT) }
      end

      context 'argument is not a directory' do
        let(:invalid) { '/etc/resolv.conf' }
        it('raises Errno::ENOTDIR') { expect { mockobj }.to raise_error(Errno::ENOTDIR) }
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
      it('returns dir name') { is_expected.to be == samples }
    end
    describe '#path' do
      subject { mailobj.path }
      it('returns String')   { is_expected.to be_a(String) }
      it('matches directory') { is_expected.to match(%r|#{samples}/.+|) }
    end
    describe '#file' do
      subject { mailobj.file }
      it('returns String')   { is_expected.to be_a(String) }
      it('returns filename') { is_expected.to match(/.+[.].+/) }
    end
    describe '#size' do
      subject { mailobj.size }
      it('returns Integer') { is_expected.to be_a(Integer) }
      it 'returns the number of files in the direcotry' do
        is_expected.to be > 255
      end
    end
    describe '#handle' do
      let(:handle) { mailobj.handle }
      subject { handle }
      it('is a IO::Dir')  { is_expected.to be_a(Dir) }
    end
    describe '#offset' do
      subject { mailobj.offset }
      it('returns Integer') { is_expected.to be_a(Integer) }
      it('is larger than 0')  { is_expected.to be > 0 }
      it('is smaller than size') { is_expected.to be < mailobj.size }
    end
    describe '#inodes' do
      let(:inodes) { mailobj.inodes }
      subject { mailobj.inodes }
      it('returns Hash') { is_expected.to be_a(Hash) }
      it('is 1 entries') { expect(inodes.size).to be == 1 }
    end

    describe '#read' do
      maildir = cn.new(sf)
      emindex = 0

      while r = maildir.read do
        emindex += 1
        mailtxt  = r
        subject { mailtxt }

        it 'is reading ' + maildir.file do
          expect(maildir.file).to match(/\A[a-z0-9]+[-]\d\d[.]eml\z/)
        end
        it('returns String') { is_expected.to be_a(String) }
        it('matches /From:/'){ is_expected.to match(/From:\s*/) }
        it "is #{mailtxt.size} bytes file" do
          expect(mailtxt.size).to be > 0
        end
        example "current position is #{maildir.offset}" do
          expect(maildir.offset).to be_a(Integer)
          expect(maildir.offset).to be > 0
        end
        example "the number of inode entries is #{maildir.inodes.size}" do
          expect(maildir.inodes.size).to be == emindex
        end
      end
    end
  end
end
