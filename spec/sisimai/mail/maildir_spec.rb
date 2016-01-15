require 'spec_helper'
require 'sisimai/mail/maildir'

describe Sisimai::Mail::Maildir do
  samplemaildir = './set-of-emails/maildir/bsd'
  let(:mailobj) { Sisimai::Mail::Maildir.new(samples) }
  let(:mockobj) { Sisimai::Mail::Maildir.new(invalid) }

  describe 'class method' do
    describe '.new' do
      context 'Maildir/ exists' do
        let(:samples) { samplemaildir }
        subject { mailobj }
        it 'returns Sisimai::Mail::Maildir object' do
          is_expected.to be_a Sisimai::Mail::Maildir
          expect(mailobj.read).to be_a String
        end
      end

      context 'directory does not exist' do
        let(:invalid) { '/etc/neko/nyan' }
        it 'raises Errno::ENOENT' do
          expect { mockobj }.to raise_error(Errno::ENOENT)
        end
      end

      context 'argument is not a directory' do
        let(:invalid) { '/etc/resolv.conf' }
        it 'raises Errno::ENOTDIR' do
          expect { mockobj }.to raise_error(Errno::ENOTDIR)
        end
      end

      context 'wrong number of arguments' do
        it 'raises ArgumentError' do
          expect { Sisimai::Mail::Maildir.new }.to raise_error(ArgumentError)
          expect { Sisimai::Mail::Maildir.new(nil, nil) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe 'instance method' do
    let(:samples) { samplemaildir }
    before do
      mailobj.read
    end
    describe '#dir' do
      subject { mailobj.dir }
      it 'returns directory name' do
        is_expected.to be_a String
        is_expected.to be == samples
      end
    end
    describe '#path' do
      subject { mailobj.path }
      it 'matches directory name' do
        is_expected.to be_a String
        is_expected.to match(%r|#{samples}/.+|)
      end
    end
    describe '#file' do
      subject { mailobj.file }
      it 'returns filename' do
        is_expected.to be_a String
        is_expected.to match(/.+[.].+/)
      end
    end
    describe '#size' do
      subject { mailobj.size }
      it 'returns the number of files in the direcotry' do
        is_expected.to be_a Integer
        is_expected.to be > 255
      end
    end
    describe '#handle' do
      let(:handle) { mailobj.handle }
      subject { handle }
      it 'is IO::Dir object' do
        is_expected.to be_a Dir
      end
    end
    describe '#offset' do
      subject { mailobj.offset }
      it 'returns valid offset value' do
        is_expected.to be_a Integer
        is_expected.to be > 0
        is_expected.to be < mailobj.size
      end
    end
    describe '#inodes' do
      let(:inodes) { mailobj.inodes }
      subject { mailobj.inodes }
      it 'contains inode table' do
        is_expected.to be_a Hash
        expect(inodes.size).to be == 1
      end
    end

    describe '#read' do
      maildir = Sisimai::Mail::Maildir.new(samplemaildir)
      emindex = 0

      while r = maildir.read do
        emindex += 1
        mailtxt  = r
        subject { mailtxt.scrub('?') }

        it 'is ' + maildir.file do
          expect(maildir.file).to match(/\A[a-z0-9]+[-]\d\d[.]eml\z/)
        end
        it 'is valid email text' do
          is_expected.to be_a String 
          is_expected.to match(/From:\s*/)
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
