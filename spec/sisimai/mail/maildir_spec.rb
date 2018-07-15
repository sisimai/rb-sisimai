require 'spec_helper'
require 'sisimai/mail/maildir'

describe Sisimai::Mail::Maildir do
  samplemaildir = './set-of-emails/maildir/bsd'
  allofthefiles = 407
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
        let(:invalid) { '/etc/hosts' }
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
    describe '#inodes' do
      let(:inodes) { mailobj.inodes }
      subject { mailobj.inodes }
      it 'contains inode table' do
        is_expected.to be_a Hash
        expect(inodes.size).to be == 1
      end
    end
    describe '#count' do
      let(:count) { mailobj.count }
      subject { mailobj.count }
      it 'returns the number of read files' do
        is_expected.to be_a Integer
        is_expected.to be == 1
      end
    end

    describe '#read' do
      maildir = Sisimai::Mail::Maildir.new(samplemaildir)
      emindex = 0

      while r = maildir.read do
        emindex += 1
        it 'is ' + maildir.file do
          expect(maildir.file).to match(/\A[a-z0-9-]+[-]\d\d[.]eml\z/)
          expect(maildir.file.size).to be > 0
        end
        it "has read #{maildir.count} files" do
          expect(maildir.count).to be > 0
          expect(maildir.count).to be == emindex
        end
        it 'has 1 or more inode entries' do
          expect(maildir.inodes.keys.size).to be_a Integer
          expect(maildir.inodes.keys.size).to be >= emindex - 3
        end
      end
      example "the number of read files is #{maildir.count}" do
        expect(maildir.count).to be > 0
        expect(maildir.count).to be == emindex
        expect(maildir.count).to be == allofthefiles
      end
    end
  end
end
