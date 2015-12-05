require 'spec_helper'
require 'sisimai/mail'
require 'sisimai/rfc3464'
require 'sisimai/rfc3834'

X = /\A(?:RFC3464|dovecot|mail[.]local|procmail|maildrop|vpopmail|vmailmgr)/
R = {
  'RFC3464' => {
    '01' => { 'status' => /\A5[.]1[.]1\z/, 'reason' => /mailboxfull/, 'agent' => /dovecot/ },
    '02' => { 'status' => /\A[45][.]0[.]\d+\z/, 'reason' => /(?:undefined|filtered|expired)/, 'agent' => /RFC3464/ },
    '03' => { 'status' => /\A[45][.]0[.]\d+\z/, 'reason' => /(?:undefined|expired)/, 'agent' => /RFC3464/ },
    '04' => { 'status' => /\A5[.]5[.]0\z/, 'reason' => /mailererror/, 'agent' => /RFC3464/ },
    '05' => { 'status' => /\A5[.]2[.]1\z/, 'reason' => /filtered/, 'agent' => /RFC3464/ },
    '06' => { 'status' => /\A5[.]5[.]0\z/, 'reason' => /userunknown/, 'agent' => /mail.local/ },
    '07' => { 'status' => /\A4[.]4[.]0\z/, 'reason' => /expired/, 'agent' => /RFC3464/ },
    '08' => { 'status' => /\A5[.]7[.]1\z/, 'reason' => /spamdetected/, 'agent' => /RFC3464/ },
    '09' => { 'status' => /\A4[.]3[.]0\z/, 'reason' => /mailboxfull/, 'agent' => /RFC3464/ },
    '10' => { 'status' => /\A5[.]1[.]1\z/, 'reason' => /userunknown/, 'agent' => /RFC3464/ },
    '11' => { 'status' => /\A5[.]\d[.]\d+\z/, 'reason' => /spamdetected/, 'agent' => /RFC3464/ },
    '12' => { 'status' => /\A4[.]3[.]0\z/, 'reason' => /mailboxfull/, 'agent' => /RFC3464/ },
    '13' => { 'status' => /\A4[.]0[.]0\z/, 'reason' => /mailererror/, 'agent' => /RFC3464/ },
    '14' => { 'status' => /\A4[.]4[.]1\z/, 'reason' => /expired/, 'agent' => /RFC3464/ },
    '15' => { 'status' => /\A5[.]0[.]\d+\z/, 'reason' => /mesgtoobig/, 'agent' => /RFC3464/ },
    '16' => { 'status' => /\A5[.]0[.]\d+\z/, 'reason' => /filtered/, 'agent' => /RFC3464/ },
    '17' => { 'status' => /\A5[.]0[.]\d+\z/, 'reason' => /expired/, 'agent' => /RFC3464/ },
    '18' => { 'status' => /\A5[.]1[.]1\z/, 'reason' => /userunknown/, 'agent' => /RFC3464/ },
    '19' => { 'status' => /\A5[.]0[.]\d+\z/, 'reason' => /onhold/, 'agent' => /RFC3464/ },
    '20' => { 'status' => /\A5[.]0[.]\d+\z/, 'reason' => /mailererror/, 'agent' => /RFC3464/ },
    '21' => { 'status' => /\A5[.]0[.]\d+\z/, 'reason' => /networkerror/, 'agent' => /RFC3464/ },
    '22' => { 'status' => /\A5[.]0[.]\d+\z/, 'reason' => /hostunknown/, 'agent' => /RFC3464/ },
    '23' => { 'status' => /\A5[.]0[.]\d+\z/, 'reason' => /mailboxfull/, 'agent' => /RFC3464/ },
    '24' => { 'status' => /\A5[.]0[.]\d+\z/, 'reason' => /onhold/, 'agent' => /RFC3464/ },
    '25' => { 'status' => /\A5[.]0[.]\d+\z/, 'reason' => /onhold/, 'agent' => /RFC3464/ },
    '26' => { 'status' => /\A5[.]1[.]1\z/, 'reason' => /userunknown/, 'agent' => /RFC3464/ },
    '27' => { 'status' => /\A4[.]4[.]6\z/, 'reason' => /networkerror/, 'agent' => /RFC3464/ },
  },
  'RFC3834' => {
    '01' => { 'status' => /\A\z/, 'reason' => /vacation/ },
    '02' => { 'status' => /\A\z/, 'reason' => /vacation/ },
    '03' => { 'status' => /\A\z/, 'reason' => /vacation/ },
  },
}

R.each_key do |e|
  cn = Module.const_get('Sisimai::' + e)

  describe cn do
    describe '.description' do
      it('returns String') { expect(cn.description).to be_a String }
      it('has the size')   { expect(cn.description.size).to be > 0 }
    end
    describe '.pattern' do
      it('returns Hash')   { expect(cn.pattern).to be_a Hash }
      it('have some keys') { expect(cn.pattern.keys.size).to be > 0 }
    end
    describe '.scan' do
      it('returns nil') { expect(cn.scan(nil,nil)).to be nil }
    end

    (1 .. R[e].keys.size).each do |i|
      emailfn = sprintf('./eg/maildir-as-a-sample/new/%s-%02d.eml', e.downcase, i)
      mailbox = Sisimai::Mail.new(emailfn)
      mailtxt = nil

      n = sprintf('%02d', i)
      next unless mailbox.path

      example("[#{n}] #{cn}/email = #{emailfn}") { expect(File.exist?(emailfn)).to be true }
      while r = mailbox.read do
        mailtxt = r
        it('returns String') { expect(mailtxt).to be_a String }
      end
    end
  end

end

