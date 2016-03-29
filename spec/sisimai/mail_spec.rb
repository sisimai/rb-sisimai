require 'spec_helper'
require 'sisimai/mail'

describe Sisimai::Mail do
  samplemailbox = './set-of-emails/mailbox/mbox-0'
  samplemaildir = './set-of-emails/maildir/err'
  let(:mailobj) { Sisimai::Mail.new(samples) }
  let(:mailbox) { Sisimai::Mail.new(samples) }
  let(:maildir) { Sisimai::Mail.new(samples) }
  let(:mockobj) { Sisimai::Mail.new(invalid) }

  describe 'class method' do
    describe '.new' do
      context 'mbox file exists' do
        let(:samples) { samplemailbox }
        subject { mailobj }
        it 'returns Sisimai::Mail object' do
          is_expected.to be_a Sisimai::Mail
        end
      end

      context 'Maildir/ exists' do
        let(:samples) { samplemaildir }
        subject { mailobj }
        it 'returns Sisimai::Mail object' do
          is_expected.to be_a Sisimai::Mail
        end
      end

      context '$stdin' do
        let(:samples) { $stdin }
        subject { mailobj }
        it 'returns Sisimai::Mail object' do
          is_expected.to be_a Sisimai::Mail
        end
      end

      context 'wrong number of arguments' do
        it 'raises ArgumentError' do
          expect { Sisimai::Mail.new }.to raise_error(ArgumentError)
          expect { Sisimai::Mail.new(nil, nil) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe 'instance method' do
    describe 'Mailbox' do
      let(:samples) { samplemailbox }
      before do
        mailbox.read
      end
      describe '#class' do
        it 'returns Sisimai::Mail' do
          expect(mailbox).to be_a Sisimai::Mail
        end
      end
      describe '#type' do
        subject { mailbox.type }
        it 'is "mailbox"' do
          is_expected.to be_a String
          is_expected.to be == 'mailbox'
        end
      end
      describe '#mail' do
        subject { mailbox.mail }
        it 'returns Sisimai::Mail::Mbox object' do
          is_expected.to be_a Sisimai::Mail::Mbox
        end
      end
      describe '#dir' do
        subject { mailbox.mail.dir }
        it 'includes ./set-of-emails' do
          is_expected.to be_a String
          is_expected.to match(%r|/set-of-emails|)
        end
      end
      describe '#path' do
        subject { mailbox.mail.path }
        it 'is equals to mailbox#path' do
          is_expected.to be_a String
          is_expected.to be == samples
          is_expected.to be == mailbox.path
        end
      end
      describe '#file' do
        subject { mailbox.mail.file }
        it 'returns filename' do
          is_expected.to be_a String
          is_expected.to be == File.basename(samples)
        end
      end
      describe '#size' do
        subject { mailbox.mail.size }
        it 'returns mbox size' do
          is_expected.to be_a Integer
          is_expected.to be == 96906
        end
      end
      describe '#handle' do
        let(:handle) { mailbox.mail.handle }
        subject { handle }
        it 'is valid IO::File object' do
          is_expected.to be_a File
          expect(handle.closed?).to be false
          expect(handle.stat.readable?).to be true
          expect(handle.stat.size).to be > 0
        end
      end
      describe '#offset' do
        subject { mailbox.mail.offset }
        it 'is valid offset value' do
          is_expected.to be_a Integer
          is_expected.to be > 0
          is_expected.to be < mailbox.mail.size
        end
      end
      describe '#read' do
        mboxobj = Sisimai::Mail.new(samplemailbox)
        emindex = 0
        hasread = 0

        while r = mboxobj.read do
          emindex += 1
          mailtxt  = r
          hasread += mailtxt.size
          subject { mailtxt }

          it "is #{mboxobj.path} ##{emindex}" do
            expect(mboxobj.path).to be == samplemailbox
          end
          it 'is valid email text' do
            is_expected.to be_a String
            is_expected.to match(/Subject:\s*/)
            expect(mailtxt.size).to be > 0
            expect(mboxobj.mail.offset).to be == hasread + 512
          end
        end

        example "the number of emails is #{emindex}" do
          expect(emindex).to be == 37
        end
        example "loaded size is #{hasread}" do
          expect(hasread).to be == mboxobj.mail.size - 512
        end
      end
    end

    describe 'Maildir/' do
      let(:samples) { samplemaildir }
      before do
        maildir.read
      end
      describe '#type' do
        subject { maildir.type }
        it 'is "maildir"' do
          is_expected.to be_a String
          is_expected.to be == 'maildir'
        end
      end
      describe '#mail' do
        subject { maildir.mail }
        it 'returns Sisimai::Mail::Maildir object' do
          is_expected.to be_a Sisimai::Mail::Maildir
        end
      end
      describe '#dir' do
        subject { maildir.mail.dir }
        it 'returns directory name' do
          is_expected.to be_a String
          is_expected.to be == samples
        end
      end
      describe '#path' do
        subject { maildir.mail.path }
        it 'matches *-01.eml' do
          is_expected.to be_a String
          is_expected.to match(/#{samples}.+[.]eml\z/)
        end
      end
      describe '#file' do
        subject { maildir.mail.file }
        it 'returns filename' do
          is_expected.to be_a String
          is_expected.to match(/make-test[-].+[.]eml\z/)
        end
      end
      describe '#size' do
        subject { maildir.mail.size }
        it 'returns the number of files in the direcotry' do
          is_expected.to be_a Integer
          is_expected.to be > 37
        end
      end
      describe '#handle' do
        let(:handle) { maildir.mail.handle }
        subject { handle }
        it 'is IO::Dir object' do
          is_expected.to be_a Dir
        end
      end
      describe '#offset' do
        subject { maildir.mail.offset }
        it 'is valid offset value' do
          is_expected.to be_a Integer
          is_expected.to be > 0
          is_expected.to be < maildir.mail.size
        end
      end
      describe '#inodes' do
        let(:inodes) { maildir.mail.inodes }
        subject { maildir.mail.inodes }
        it 'contains inode table' do
          is_expected.to be_a Hash
          expect(inodes.size).to be == 1
        end
      end
      describe '#count' do
        let(:count) { maildir.mail.count }
        subject { maildir.mail.count }
        it 'returns the number of read files' do
          is_expected.to be_a Integer
          is_expected.to be == 1
        end
      end

      describe '#read' do
        mdirobj = Sisimai::Mail.new(samplemaildir)
        emindex = 0

        while r = mdirobj.read do
          emindex += 1

          it 'is ' + mdirobj.mail.file do
            expect(mdirobj.mail.file).to match(/\A.+[.]eml\z/)
          end
          example "current position is #{mdirobj.mail.offset}" do
            expect(mdirobj.mail.offset).to be_a(Integer)
            expect(mdirobj.mail.offset).to be > 0
          end
          example "the number of read files is #{mdirobj.mail.inodes.size}" do
            expect(mdirobj.mail.count).to be == emindex
          end
        end

      end
    end
  end
end
