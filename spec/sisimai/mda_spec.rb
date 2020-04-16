require 'spec_helper'
require 'sisimai/mda'
require 'sisimai/mail'

describe Sisimai::MDA do
  cn = Sisimai::MDA

  smtperrors = [
    'Your message to neko was automatically rejected:'+"\n"+'Not enough disk space',
    'mail.local: Disc quota exceeded',
    'procmail: Quota exceeded while writing',
    'maildrop: maildir over quota.',
    'vdelivermail: user is over quota',
    'vdeliver: Delivery failed due to system quota violation',
  ]
  emailfn = './set-of-emails/maildir/bsd/rfc3464-01.eml'
  mailbox = Sisimai::Mail.new(emailfn)
  message = nil
  headers = { 'from' => 'Mail Delivery Subsystem' }

  describe '.make' do
    context 'valid mailbox data' do
      while r = mailbox.data.read do
        smtperrors.each do |e|
          v = cn.make(headers,e)
          it('returns Hash') { expect(v).to be_a Hash }
          it('has "mda" key') { expect(v['mda']).to be_a String }
          it('has "reason" key') { expect(v['reason']).to be_a String }
          it('has "message" key') { expect(v['message']).to be_a String }

          example('"mda" is MDA name') { expect(v['mda'].size).to be > 0 }
          example('"reason" is bounce reason') { expect(v['reason'].size).to be > 0 }
          example('"message" is error message') { expect(v['message'].size).to be > 0 }
        end
      end
    end
    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { cn.make }.to raise_error(ArgumentError)
      end
      it 'raises ArgumentError' do
        expect { cn.make(nil) }.to raise_error(ArgumentError)
      end
      it 'raises ArgumentError' do
        expect { cn.make(nil,nil,nil) }.to raise_error(ArgumentError)
      end
    end
  end


end
