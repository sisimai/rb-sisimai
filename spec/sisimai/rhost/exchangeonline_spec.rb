require 'spec_helper'
require 'sisimai/mail'
require 'sisimai/data'
require 'sisimai/message'
require 'sisimai/rhost/exchangeonline'

describe Sisimai::Rhost::ExchangeOnline do
  rs = {
    '01' => { 'status' => %r/\A5[.]7[.]606\z/, 'reason' => %r/blocked/ },
    '02' => { 'status' => %r/\A5[.]4[.]1\z/,   'reason' => %r/userunknown/ },
    '03' => { 'status' => %r/\A5[.]1[.]10\z/,  'reason' => %r/userunknown/ },
  }
  describe 'bounce mail from Exchange Online' do
    rs.each_key.each do |n|
      emailfn = sprintf('./set-of-emails/maildir/bsd/rhost-exchange-online-%02d.eml', n)
      next unless File.exist?(emailfn)

      mailbox = Sisimai::Mail.new(emailfn)
      mtahost = %r/.+[.](?:prod|protection)[.]outlook[.]com/
      next unless mailbox

      while r = mailbox.read do
        mesg = Sisimai::Message.new(data: r)
        it('is Sisimai::Message object') { expect(mesg).to be_a Sisimai::Message }
        it('has array in "ds" accessor' ) { expect(mesg.ds).to be_a Array }
        it('has hash in "header" accessor' ) { expect(mesg.header).to be_a Hash }
        it('has hash in "rfc822" accessor' ) { expect(mesg.rfc822).to be_a Hash }
        it('has From line in "from" accessor' ) { expect(mesg.from.size).to be > 0 }

        mesg.ds.each do |e|
          example('spec is "SMTP"') { expect(e['spec']).to be == 'SMTP' }
          example 'recipient is email address' do
            expect(e['recipient']).to match(/\A.+[@].+[.].+\z/)
          end
          example('status is DSN') { expect(e['status']).to match(/\A\d[.]\d[.]\d+\z/) }
          example('command is ' + e['command']) { expect(e.key?('command')).to be true }
          example('date is not empty') { expect(e['date']).not_to be_empty }
          example('diagnosis is not empty') { expect(e['diagnosis']).not_to be_empty }
          example('action is not empty') { expect(e['action']).not_to be_empty }
          example('rhost is ' + e['rhost']) { expect(e['rhost']).to match(mtahost) }
          example('alias is ' + e['alias']) { expect(e.key?('alias')).to be true }
          example('agent is ' + e['agent']) { expect(e['agent']).to match(/(?:Email::.+|RFC3464)/) }
        end

        data = Sisimai::Data.make(data: mesg)
        data.each do |e|
          example('reason is String') { expect(e.reason.size).to be > 0 }
          example('reason matches') { expect(e.reason).to match(rs[n]['reason']) }
        end
      end
    end

  end
end

