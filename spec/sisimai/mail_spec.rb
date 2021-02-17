require 'spec_helper'
require 'sisimai/mail'

describe Sisimai::Mail do
  samplemailbox = './set-of-emails/mailbox/mbox-0'
  samplemaildir = './set-of-emails/maildir/err'
  let(:mailobj) { Sisimai::Mail.new(samples) }
  let(:mailbox) { Sisimai::Mail.new(samples) }
  let(:maildir) { Sisimai::Mail.new(samples) }
  let(:devices) { Sisimai::Mail.new(samples) }
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
    describe 'Standard-In' do
      let(:samples) { STDIN }
      describe '#class' do
        it('returns Sisimai::Mail') { expect(devices).to be_a Sisimai::Mail }
      end
      describe '#kind' do
        it('is "stdin"') { expect(devices.kind).to be == 'stdin' }
      end
      describe '#path' do
        it('returns <STDIN>') { expect(devices.path).to be == '<STDIN>' }
      end
      describe '#data ' do
        it('returns "Sisimai::Mail::STDIN"') { expect(devices.data).to be_a Sisimai::Mail::STDIN }
      end
    end

    describe 'Mailbox' do
      let(:samples) { samplemailbox }
      before do
        mailbox.data.read
      end
      describe '#class' do
        it 'returns Sisimai::Mail' do
          expect(mailbox).to be_a Sisimai::Mail
        end
      end
      describe '#kind' do
        subject { mailbox.kind }
        it 'is "mailbox"' do
          is_expected.to be_a String
          is_expected.to be == 'mailbox'
        end
      end
      describe '#data' do
        subject { mailbox.data }
        it 'returns Sisimai::Mail::Mbox object' do
          is_expected.to be_a Sisimai::Mail::Mbox
        end
      end
      describe '#dir' do
        subject { mailbox.data.dir }
        it 'includes ./set-of-emails' do
          is_expected.to be_a String
          is_expected.to match(%r|/set-of-emails|)
        end
      end
      describe '#path' do
        subject { mailbox.data.path }
        it 'is equals to mailbox#path' do
          is_expected.to be_a String
          is_expected.to be == samples
          is_expected.to be == mailbox.path
        end
      end
      describe '#file' do
        subject { mailbox.data.file }
        it 'returns filename' do
          is_expected.to be_a String
          is_expected.to be == File.basename(samples)
        end
      end
      describe '#size' do
        subject { mailbox.data.size }
        it 'returns mbox size' do
          is_expected.to be_a Integer
          is_expected.to be == 96906
        end
      end
      describe '#handle' do
        let(:handle) { mailbox.data.handle }
        subject { handle }
        it 'is valid IO::File object' do
          is_expected.to be_a File
          expect(handle.closed?).to be false
          expect(handle.stat.readable?).to be true
          expect(handle.stat.size).to be > 0
        end
      end
      describe '#offset' do
        subject { mailbox.data.offset }
        it 'is valid offset value' do
          is_expected.to be_a Integer
          is_expected.to be > 0
          is_expected.to be < mailbox.data.size
        end
      end
      describe '#read' do
        mboxobj = Sisimai::Mail.new(samplemailbox)
        emindex = 0
        hasread = 0

        while r = mboxobj.data.read do
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

    describe 'Maildir/' do
      let(:samples) { samplemaildir }
      before do
        maildir.data.read
      end
      describe '#kind' do
        subject { maildir.kind }
        it 'is "maildir"' do
          is_expected.to be_a String
          is_expected.to be == 'maildir'
        end
      end
      describe '#data' do
        subject { maildir.data }
        it 'returns Sisimai::Mail::Maildir object' do
          is_expected.to be_a Sisimai::Mail::Maildir
        end
      end
      describe '#dir' do
        subject { maildir.data.dir }
        it 'returns directory name' do
          is_expected.to be_a String
          is_expected.to be == samples
        end
      end
      describe '#path' do
        subject { maildir.data.path }
        it 'matches *-01.eml' do
          is_expected.to be_a String
          is_expected.to match(/#{samples}.+[.]eml\z/)
        end
      end
      describe '#file' do
        subject { maildir.data.file }
        it 'returns filename' do
          is_expected.to be_a String
          is_expected.to match(/make-test[-].+[.]eml\z/)
        end
      end
      describe '#size' do
        subject { maildir.data.size }
        it 'returns the number of files/directories in the Maildir/' do
          is_expected.to be_a Integer
          is_expected.to be > 37
        end
      end
      describe '#handle' do
        let(:handle) { maildir.data.handle }
        subject { handle }
        it 'is IO::Dir object' do
          is_expected.to be_a Dir
        end
      end

      describe '#read' do
        mdirobj = Sisimai::Mail.new(samplemaildir)
        emindex = 0

        while r = mdirobj.data.read do
          emindex += 1

          it 'is ' + mdirobj.data.file do
            expect(mdirobj.data.file).to match(/\A.+[.]eml\z/)
          end
          example "the number of read files is #{mdirobj.data.offset}" do
            expect(mdirobj.data.offset).to be == emindex + 2
          end
        end

      end
    end
  end
end
