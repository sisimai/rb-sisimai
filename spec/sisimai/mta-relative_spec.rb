require 'spec_helper'
require 'sisimai/mail'
require 'sisimai/rfc3834'

X = /\A(?:RFC3464|dovecot|mail[.]local|procmail|maildrop|vpopmail|vmailmgr)/
R = {
  'RFC3834' => {
    '01' => { 'status' => /\A\z/, 'reason' => /vacation/ },
    '02' => { 'status' => /\A\z/, 'reason' => /vacation/ },
    '03' => { 'status' => /\A\z/, 'reason' => /vacation/ },
  },
};

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

