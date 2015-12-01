require 'spec_helper'
require 'sisimai/mail'

describe Sisimai::Mail do
  cn = Sisimai::Mail
  sf = './eg/mbox-as-a-sample'
  sd = './eg/maildir-as-a-sample/new'
  let(:mailobj) { cn.new(samples) }
  let(:mailbox) { cn.new(samples) }
  let(:maildir) { cn.new(samples) }
  let(:mockobj) { cn.new(invalid) }

  describe 'Class method' do
    describe '.new' do
      context 'mbox file exists' do
        let(:samples) { sf }
        subject { mailobj }
        it("returns #{cn} object"){ is_expected.to be_a(cn) }
      end

      context 'Maildir/ exists' do
        let(:samples) { sd }
        subject { mailobj }
        it("returns #{cn} object") { is_expected.to be_a(cn) }
      end

      context '$stdin' do
        let(:samples) { $stdin }
        subject { mailobj }
        it("returns #{cn} object"){ is_expected.to be_a(cn) }
      end

      describe 'wrong number of arguments' do
        it 'raises ArgumentError' do
          expect { cn.new }.to raise_error(ArgumentError)
        end
        it 'raises ArgumentError' do
          expect { cn.new(nil, nil) }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe 'Instance method' do
    describe 'Mailbox' do
      let(:samples) { sf }
      before do
        mailbox.read
      end
      describe '#class' do
        it('returns Sisimai::Mail') { expect(mailbox.class).to be == Sisimai::Mail }
      end
      describe '#type' do
        subject { mailbox.type }
        it('returns String') { is_expected.to be_a(String) }
        it('is "mailbox"')   { is_expected.to be == 'mailbox' }
      end
      describe '#mail' do
        subject { mailbox.mail }
        it('returns Sisimai::Mail::Mbox object') { is_expected.to be_a(Sisimai::Mail::Mbox) }
      end
      describe '#dir' do
        subject { mailbox.mail.dir }
        it('returns String') { is_expected.to be_a(String) }
        it('includes ./eg')  { is_expected.to match(%r|/eg|) }
      end
      describe '#path' do
        subject { mailbox.mail.path }
        it('returns String') { is_expected.to be_a(String) }
        it('returns path')   { is_expected.to be == samples }
        it('is equals to mailbox#path') { is_expected.to be == mailbox.path }
      end
      describe '#file' do
        subject { mailbox.mail.file }
        it('returns String')   { is_expected.to be_a(String) }
        it('returns filename') { is_expected.to be == File.basename(samples) }
      end
      describe '#size' do
        subject { mailbox.mail.size }
        it('returns Integer') { is_expected.to be_a(Integer) }
        it('returns 96906')   { is_expected.to be == 96906 }
      end
      describe '#handle' do
        let(:handle) { mailbox.mail.handle }
        subject { handle }
        it('is a IO::File') { is_expected.to be_a(File) }
        it('is not closed') { expect(handle.closed?).to be false }
        it('is readable')   { expect(handle.stat.readable?).to be true }
        it('has a size')    { expect(handle.stat.size).to be > 0 }
      end
      describe '#offset' do
        subject { mailbox.mail.offset }
        it('returns Integer') { is_expected.to be_a(Integer) }
        it('is larger than 0') { is_expected.to be > 0 }
        it('is smaller than size') { is_expected.to be < mailbox.mail.size }
      end
      describe '#read' do
        mboxobj = cn.new(sf)
        emindex = 0
        hasread = 0

        while r = mboxobj.read do
          emindex += 1
          mailtxt  = r
          hasread += mailtxt.size
          subject { mailtxt }

          it "is reading #{mboxobj.path} ##{emindex}" do
            expect(mboxobj.path).to be == sf
          end
          it('returns String') { is_expected.to be_a(String) }
          it('matches /From /'){ is_expected.to match(/Subject:\s*/) }
          it "is #{mailtxt.size} bytes file" do
            expect(mailtxt.size).to be > 0
          end
          example "current position is #{mboxobj.mail.offset}" do
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
      let(:samples) { sd }
      before do
        maildir.read
      end
      describe '#type' do
        subject { maildir.type }
        it('returns String') { is_expected.to be_a(String) }
        it('is "maildir"')   { is_expected.to be == 'maildir' }
      end
      describe '#mail' do
        subject { maildir.mail }
        it('returns Sisimai::Mail::Maildir object') { is_expected.to be_a(Sisimai::Mail::Maildir) }
      end
      describe '#dir' do
        subject { maildir.mail.dir }
        it('returns String') { is_expected.to be_a(String) }
        it('returns dir name') { is_expected.to be == samples }
      end
      describe '#path' do
        subject { maildir.mail.path }
        it('returns String')   { is_expected.to be_a(String) }
        it('matches *-01.eml') { is_expected.to match(/#{samples}.+[-]01[.]eml\z/) }
      end
      describe '#file' do
        subject { maildir.mail.file }
        it('returns String')   { is_expected.to be_a(String) }
        it('returns filename') { is_expected.to match(/[-]01[.]eml\z/) }
      end
      describe '#size' do
        subject { maildir.mail.size }
        it('returns Integer') { is_expected.to be_a(Integer) }
        it 'returns the number of files in the direcotry' do
          is_expected.to be > 255
        end
      end
      describe '#handle' do
        let(:handle) { maildir.mail.handle }
        subject { handle }
        it('is a IO::Dir')  { is_expected.to be_a(Dir) }
      end
      describe '#offset' do
        subject { maildir.mail.offset }
        it('returns Integer') { is_expected.to be_a(Integer) }
        it('is equals to 3')  { is_expected.to be == 3 }
        it('is smaller than size') { is_expected.to be < maildir.mail.size }
      end
      describe '#inodes' do
        let(:inodes) { maildir.mail.inodes }
        subject { maildir.mail.inodes }
        it('returns Hash') { is_expected.to be_a(Hash) }
        it('is 1 entries') { expect(inodes.size).to be == 1 }
      end

      describe '#read' do
        mdirobj = cn.new(sd)
        emindex = 0

        while r = mdirobj.read do
          emindex += 1
          mailtxt  = r
          subject { mailtxt }

          it 'is reading ' + mdirobj.mail.file do
            expect(mdirobj.mail.file).to match(/\A[a-z0-9]+[-]\d\d[.]eml\z/)
          end
          it('returns String') { is_expected.to be_a(String) }
          it('matches /From /'){ is_expected.to match(/Subject:\s*/) }
          it "is #{mailtxt.size} bytes file" do
            expect(mailtxt.size).to be > 0
          end
          example "current position is #{mdirobj.mail.offset}" do
            expect(mdirobj.mail.offset).to be == emindex + 2
          end
          example "the number of inode entries is #{mdirobj.mail.inodes.size}" do
            expect(mdirobj.mail.inodes.size).to be == emindex
          end
        end
      end
    end
  end
end
