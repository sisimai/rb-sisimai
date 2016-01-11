require 'spec_helper'
require 'sisimai/mail'
require 'sisimai/data'
require 'sisimai/message'
require 'sisimai/rhost/googleapps'

describe Sisimai::Rhost::GoogleApps do
  cn = Sisimai::Rhost::GoogleApps
  rs = {
    '01' => { 'status' => %r/\A5[.]2[.]1\z/, 'reason' => %r/suspend/ },
  }
  describe 'bounce mail from GoogleApps' do
    rs.each_key.each do |n|
      emailfn = sprintf('./set-of-emails/maildir/bsd/google-apps-%02d.eml', n)
      next unless File.exist?(emailfn)

      mailbox = Sisimai::Mail.new(emailfn)
      mtahost = 'aspmx.l.google.com'
      next unless mailbox

      while r = mailbox.read do
        p = Sisimai::Message.new( data: r )
        subject { p }
        it('is Sisimai::Message object') { is_expected.to be_a Sisimai::Message }
        it('has array in "ds" accessor' ) { expect(p.ds).to be_a Array }
        it('has hash in "header" accessor' ) { expect(p.header).to be_a Hash }
        it('has hash in "rfc822" accessor' ) { expect(p.rfc822).to be_a Hash }
        it('has From line in "from" accessor' ) { expect(p.from.size).to be > 0 }

        p.ds.each do |e|
          example('spec is "SMTP"') { expect(e['spec']).to be == 'SMTP' }
          example 'recipient is email address' do
            expect(e['recipient']).to match(/\A.+[@].+[.].+\z/)
          end
          example('status is DSN') { expect(e['status']).to match(/\A\d[.]\d[.]\d\z/) }
          example('command is SMTP command') { expect(e['command']).to match(/\A[A-Z]{4}\z/) }
          example('date is not empty') { expect(e['date']).not_to be_empty }
          example('diagnosis is not empty') { expect(e['diagnosis']).not_to be_empty }
          example('action is not empty') { expect(e['action']).not_to be_empty }
          example('rhost is ' + mtahost) { expect(e['rhost']).to be == mtahost }
          example('alias is ""') { expect(e['alias']).to be_empty }
          example('agent is Sendmail') { expect(e['agent']).to be == 'Sendmail' }
        end

        v = Sisimai::Data.make( data: p )
        v.each do |e|
          example('reason is String') { expect(e.reason.size).to be > 0 }
          example('reason matches') { expect(e.reason).to match(rs[n]['reason']) }
        end
      end
    end

  end
end

