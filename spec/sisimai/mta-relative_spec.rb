require 'spec_helper'
require 'sisimai/mail'
require 'sisimai/data'
require 'sisimai/message'
require 'sisimai/arf'
require 'sisimai/rfc3464'
require 'sisimai/rfc3834'

X = /\A(?:RFC3464|dovecot|mail[.]local|procmail|maildrop|vpopmail|vmailmgr)/
R = {
  'ARF' => {
    '01' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /abuse/ },
    '02' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /abuse/ },
    '03' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /abuse/ },
    '04' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /abuse/ },
    '05' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /abuse/ },
    '06' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /abuse/ },
    '07' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /auth-failure/ },
    '08' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /auth-failure/ },
    '09' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /auth-failure/ },
    '10' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /abuse/ },
    '11' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /abuse/ },
    '12' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /opt-out/ },
    '13' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /abuse/ },
    '14' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /auth-failure/ },
    '15' => { 'status' => /\A\z/, 'reason' => /feedback/, 'feedbacktype' => /abuse/ },
  },
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

R.each_key do |x|
  cn = Module.const_get('Sisimai::' + x)

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

    (1 .. R[x].keys.size).each do |i|
      emailfn = sprintf('./eg/maildir-as-a-sample/new/%s-%02d.eml', x.downcase, i)
      mailbox = Sisimai::Mail.new(emailfn)
      mailtxt = nil

      n = sprintf('%02d', i)
      next unless mailbox.path

      example sprintf('[%s] %s/mail = %s', n, cn, emailfn) do
        expect(File.exist?(emailfn)).to be true
      end

      while r = mailbox.read do
        mailtxt = r
        it('returns String') { expect(mailtxt).to be_a String }
        p = Sisimai::Message.new( { 'data' => r } )

        it('returns Sisimai::Message object') { expect(p).to be_a Sisimai::Message }
        example('Array in ds accessor') { expect(p.ds).to be_a Array }
        example('Hash in header accessor') { expect(p.header).to be_a Hash }
        example('Hash in rfc822 accessor') { expect(p.rfc822).to be_a Hash }
        example('#from returns String') { expect(p.from).to be_a String }

        example sprintf('[%s] %s#from = %s', n, cn, p.from) do
          expect(p.from.size).to be > 0
        end

        p.ds.each do |e|
          ['recipient', 'agent'].each do |ee|
            example sprintf('[%s] %s[%s] = %s', n, x, ee, e[ee]) do
              expect(e[ee].size).to be > 0
            end
          end

          %w[
            date spec reason status command action alias rhost lhost diagnosis
            feedbacktype softbounce
          ].each do |ee|
            example sprintf('[%s] %s[%s] = %s', n, x, ee, e[ee]) do
              expect(e.key?(ee)).to be true
            end
          end

          if x == 'ARF'
            example sprintf('[%s] %s[feedbacktype] = %s', n, x, e['feedbacktype']) do
              expect(e['feedbacktype']).to match(R['ARF'][n]['feedbacktype'])
            end
          end

          unless x == 'mFILTER'
            if x == 'RFC3464'
              example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
                expect(e['agent']).to match(X)
              end
            else
              example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
                expect(e['agent']).to be_a String
              end
            end
          end

          example sprintf('[%s] %s[recipient] = %s', n, x, e['recipient']) do
            expect(e['recipient']).to match(/[0-9A-Za-z@-_.]+/)
            expect(e['recipient']).not_to match(/[ ]/)
          end

          example sprintf('[%s] %s[command] = %s', n, x, e['command']) do
            expect(e['command']).not_to match(/[ ]/)
          end

          if e['status'] && e['status'].size > 0
            example sprintf('[%s] %s[status] = %s', n, x, e['status']) do
              expect(e['status']).to match(/\A(?:[45][.]\d[.]\d+)\z/)
            end
          end

          if e['action'].size > 0
            example sprintf('[%s] %s[action] = %s', n, x, e['action']) do
              expect(e['action']).to match(/\A(?:fail.+|delayed|expired)\z/)
            end
          end

          ['rhost', 'lhost'].each do |ee|
            next unless e[ee]
            next unless e[ee].size > 0
            next if x =~ /\A(?:qmail|Exim|Exchange|X4)\z/
            example sprintf('[%s] %s[%s] = %s', n, x, ee, e[ee]) do
              expect(e[ee]).to match(/\A(?:localhost|.+[.].+)\z/)
            end
          end
        end

        o = Sisimai::Data.make( { 'data' => p } )
        it 'returns Array' do
          expect(o).to be_a Array
          expect(o.size).to be > 0
        end

        o.each do |e|
          it('is Sisimai::Data object') { expect(e).to be_a Sisimai::Data }
          example '#timestamp returns Sisimai::Time' do
            expect(e.timestamp).to be_a Sisimai::Time
          end
          example '#addresser returns Sisimai::Address' do
            expect(e.addresser).to be_a Sisimai::Address
          end
          example '#recipient returns Sisimai::Address' do
            expect(e.recipient).to be_a Sisimai::Address
          end

          %w[replycode subject smtpcommand diagnosticcode diagnostictype].each do |ee|
            example sprintf('[%s] %s#%s = %s', n, x, ee, e.send(ee)) do
              expect(e.send(ee)).to be_a String
            end
          end

          example sprintf('[%s] %s#deliverystatus = %s', n, x, e.deliverystatus) do
            expect(e.deliverystatus).to be_a String
            if x == 'ARF' || x == 'RFC3834'
              expect(e.deliverystatus).to be_empty
            else
              expect(e.deliverystatus).not_to be_empty
            end
          end

          %w[token smtpagent timezoneoffset].each do |ee|
            example sprintf('[%s] %s#%s = %s', n, x, ee, e.send(ee)) do
              expect(e.send(ee)).to be_a String
            end
          end

          example sprintf('[%s] %s#senderdomain = %s', n, x, e.senderdomain) do
            expect(e.addresser.host).to be == e.senderdomain
          end

          example sprintf('[%s] %s#destination = %s', n, x, e.destination) do
            expect(e.recipient.host).to be == e.destination
          end

          example sprintf('[%s] %s#softbounce = %s', n, x, e.softbounce) do
            if e.deliverystatus[0,1].to_i == 4
              expect(e.softbounce).to be == 1
            elsif e.deliverystatus[0,1].to_i == 5
              expect(e.softbounce).to be == 0
            else
              expect(e.softbounce).to be == -1
            end
          end

          example sprintf('[%s] %s#replycode = %s', n, x, e.replycode) do
            expect(e.replycode).to match(/\A(?:[45]\d\d|)\z/)
          end

          example sprintf('[%s] %s#timezoneoffset = %s', n, x, e.timezoneoffset) do
            expect(e.timezoneoffset).to match(/\A[-+]\d{4}\z/)
          end

          example sprintf('[%s] %s#deliverystatus = %s', n, x, e.deliverystatus) do
            expect(e.deliverystatus).to match(R[x][n]['status'])
          end

          example sprintf('[%s] %s#reason = %s', n, x, e.reason) do
            expect(e.reason).to match(R[x][n]['reason'])
          end

          example sprintf('[%s] %s#token = %s', n, x, e.token) do
            expect(e.token).to match(/\A[0-9a-f]{40}\z/)
          end

          if x == 'ARF'
            example sprintf('[%s] %s#feedbacktype = %s', n, x, e.feedbacktype) do
              expect(e.feedbacktype).to match(R['ARF'][n]['feedbacktype'])
            end
          end

          %w[deliverystatus diagnostictype smtpcommand lhost rhost alias listid
            action messageid]. each do |ee|
            example sprintf('[%s] %s#%s = %s', n, x, ee, e.send(ee)) do
              expect(e.send(ee)).not_to match(/[ ]/)
            end
          end

          %w[addresser recipient].each do |ee|
            %w[user host verp alias].each do |eee|
              example sprintf('[%s] %s#%s#%s = %s', n, x, ee, eee, e.send(ee).send(eee)) do
                expect(e.send(ee).send(eee)).not_to match(/[ ]/)
              end
            end
          end
        end
      end
    end
  end

end

