require 'spec_helper'
require 'sisimai'
require 'sisimai/mail/maildir'
require 'sisimai/message'
require 'json'

cannotparse = './set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet'
if File.exist?(cannotparse)
  describe Sisimai do
    it 'returns nil' do
      expect(Sisimai.make(cannotparse)).to be nil
    end
  end

  describe Sisimai::Mail::Maildir do
    maildir = Sisimai::Mail::Maildir.new(cannotparse)

    describe 'Sisimai::Mail::Maildir' do
      it 'is Sisimai::Mail::Maildir' do
        expect(maildir).to be_a Sisimai::Mail::Maildir
      end

      describe 'each method' do
        example '#dir returns directory name' do
          expect(maildir.dir).to be == cannotparse
        end
        example '#file retuns nil' do
          expect(maildir.file).to be nil
        end
        example '#inodes is Hash' do
          expect(maildir.inodes).to be_a Hash
        end
        example '#handle is Dir' do
          expect(maildir.handle).to be_a Dir
        end

        describe '#read' do
          mailobj = Sisimai::Mail::Maildir.new(cannotparse)
          mailtxt = mailobj.read

          it 'returns message string' do
            expect(mailtxt).to be_a String
            expect(mailtxt.size).to be > 0
          end
        end
      end
    end
  end

  describe Sisimai::Message do
    seekhandle = Dir.open(cannotparse)
    mailastext = ''

    while r = seekhandle.read do
      next if r == '.' || r == '..'
      emailindir = sprintf('%s/%s', cannotparse, r)
      emailindir = emailindir.squeeze('/')

      next unless File.ftype(emailindir) == 'file'
      next unless File.size(emailindir) > 0
      next unless File.readable?(emailindir)

      filehandle = File.open(emailindir,'r')
      mailastext = filehandle.read
      filehandle.close

      it 'returns String' do
        expect(mailastext).to be_a String
        expect(mailastext.size).to be > 0
      end

      p = Sisimai::Message.new(data: mailastext)
      it 'returns Sisimai::Message' do
        expect(p).to be_a Sisimai::Message
        expect(p.ds).to be nil
        expect(p.from).to be nil
        expect(p.rfc822).to be nil
        expect(p.header).to be nil
      end
    end

  end
end
