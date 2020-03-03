require 'spec_helper'
require 'sisimai/mail'
require 'sisimai/data'
require 'sisimai/message'
require 'sisimai/rhost/franceptt'

describe Sisimai::Rhost::FrancePTT do
  rs = {
    '01' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
    '02' => { 'status' => %r/\A5[.]5[.]0\z/, 'reason' => %r/userunknown/ },
    '03' => { 'status' => %r/\A5[.]2[.]0\z/, 'reason' => %r/spamdetected/ },
    '04' => { 'status' => %r/\A5[.]2[.]0\z/, 'reason' => %r/spamdetected/ },
    '05' => { 'status' => %r/\A5[.]5[.]0\z/, 'reason' => %r/suspend/ },
    '06' => { 'status' => %r/\A4[.]0[.]0\z/, 'reason' => %r/blocked/ },
    '07' => { 'status' => %r/\A4[.]0[.]0\z/, 'reason' => %r/blocked/ },
    '08' => { 'status' => %r/\A4[.]2[.]0\z/, 'reason' => %r/systemerror/ },
    '10' => { 'status' => %r/\A4[.]5[.]0\z/, 'reason' => %r/undefined/ },
    '11' => { 'status' => %r/\A4[.]2[.]1\z/, 'reason' => %r/undefined/ },
  }
  describe 'bounce mail from FrancePTT' do
    rs.each_key.each do |n|
      emailfn = sprintf('./set-of-emails/maildir/bsd/rhost-franceptt-%02d.eml', n.to_i)
      next unless File.exist?(emailfn)

      mailbox = Sisimai::Mail.new(emailfn)
      mtahost = %r/(?:smtp-in[.]orange[.]fr|smtpz4[.]laposte[.]net|smtp[.]wanadoo[.]fr)/
      next unless mailbox

      while r = mailbox.read do
        mesg = Sisimai::Message.new(data: r)
        it('is Sisimai::Message object') { expect(mesg).to be_a Sisimai::Message }
        it('has array in "ds" accessor' ) { expect(mesg.ds).to be_a Array }
        it('has hash in "header" accessor' ) { expect(mesg.header).to be_a Hash }
        it('has hash in "rfc822" accessor' ) { expect(mesg.rfc822).to be_a Hash }
        it('has From line in "from" accessor' ) { expect(mesg.from.size).to be > 0 }

        mesg.ds.each do |e|
          example('Key "spec" exists') { expect(e.has_key?('spec')).to be true }
          example 'recipient is email address' do
            expect(e['recipient']).to match(/\A.+[@].+[.].+\z/)
          end
          example('status is DSN') { expect(e['status']).to match(/\A\d[.]\d[.]\d\z/) }
          example('command is SMTP command') { expect(e['command']).to match(/\A[A-Z]{4}\z/) }
          example('Key "date" exists') { expect(e.has_key?('date')).to be true }
          example('diagnosis is not empty') { expect(e['diagnosis']).not_to be_empty }
          example('Key "action" exists') { expect(e.has_key?('action')).to be true }
          example('rhost is ' + e['rhost']) { expect(e['rhost']).to match(mtahost) }
          example('alias exists') { expect(e.key?('alias')).to be true }
          example('agent is ' + e['agent']) { expect(e['agent']).to match(/(?:EinsUndEins|Exim|Postfix|Sendmail)/) }
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

