require 'spec_helper'
require 'sisimai/mail'
require 'sisimai/data'
require 'sisimai/message'
require 'sisimai/arf'
require 'sisimai/rfc3464'
require 'sisimai/rfc3834'

describe 'Sisimai::*' do
  MDAPatterns = /\A(?:RFC3464|dovecot|mail[.]local|procmail|maildrop|vpopmail|vmailmgr)/
  MTARelative = {
    'ARF' => {
      '01' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => %r/\A-1\z/ },
      '02' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => %r/\A-1\z/ },
      '03' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => %r/\A-1\z/ },
      '04' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => %r/\A-1\z/ },
      '05' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => %r/\A-1\z/ },
      '06' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => %r/\A-1\z/ },
      '07' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /auth-failure/, 'b' => %r/\A-1\z/ },
      '08' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /auth-failure/, 'b' => %r/\A-1\z/ },
      '09' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /auth-failure/, 'b' => %r/\A-1\z/ },
      '10' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => %r/\A-1\z/ },
      '11' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/, 'b' => %r/\A-1\z/ },
      '12' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /opt-out/, 'b' => %r/\A-1\z/ },
      '13' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/,   'b' => %r/\A-1\z/ },
      '14' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /auth-failure/, 'b' => %r/\A-1\z/ },
      '15' => { 's' => /\A\z/, 'r' => /feedback/, 'f' => /abuse/,   'b' => %r/\A-1\z/ },
    },
    'RFC3464' => {
      '01' => { 's' => /\A5[.]1[.]1\z/,     'r' => /mailboxfull/, 'a' => /dovecot/, 'b' => %r/\A1\z/ },
      '02' => { 's' => /\A[45][.]0[.]\d+\z/,'r' => /(?:undefined|filtered|expired)/, 'a' => /RFC3464/, 'b' => %r/\d\z/ },
      '03' => { 's' => /\A[45][.]0[.]\d+\z/,'r' => /(?:undefined|expired)/, 'a' => /RFC3464/, 'b' => %r/\d\z/ },
      '04' => { 's' => /\A5[.]5[.]0\z/,     'r' => /mailererror/, 'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '05' => { 's' => /\A5[.]2[.]1\z/,     'r' => /filtered/,    'a' => /RFC3464/,    'b' => %r/\A1\z/ },
      '06' => { 's' => /\A5[.]5[.]0\z/,     'r' => /userunknown/, 'a' => /mail.local/, 'b' => %r/\A0\z/ },
      '07' => { 's' => /\A4[.]4[.]0\z/,     'r' => /expired/,     'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '08' => { 's' => /\A5[.]7[.]1\z/,     'r' => /spamdetected/,'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '09' => { 's' => /\A4[.]3[.]0\z/,     'r' => /mailboxfull/, 'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '10' => { 's' => /\A5[.]1[.]1\z/,     'r' => /userunknown/, 'a' => /RFC3464/, 'b' => %r/\A0\z/ },
      '11' => { 's' => /\A5[.]\d[.]\d+\z/,  'r' => /spamdetected/,'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '12' => { 's' => /\A4[.]3[.]0\z/,     'r' => /mailboxfull/, 'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '13' => { 's' => /\A4[.]0[.]0\z/,     'r' => /mailererror/, 'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '14' => { 's' => /\A4[.]4[.]1\z/,     'r' => /expired/,     'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '15' => { 's' => /\A5[.]0[.]\d+\z/,   'r' => /mesgtoobig/,  'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '16' => { 's' => /\A5[.]0[.]\d+\z/,   'r' => /filtered/,    'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '17' => { 's' => /\A5[.]0[.]\d+\z/,   'r' => /expired/,     'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '18' => { 's' => /\A5[.]1[.]1\z/,     'r' => /userunknown/, 'a' => /RFC3464/, 'b' => %r/\A0\z/ },
      '19' => { 's' => /\A5[.]0[.]\d+\z/,   'r' => /onhold/,      'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '20' => { 's' => /\A5[.]0[.]\d+\z/,   'r' => /mailererror/, 'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '21' => { 's' => /\A5[.]0[.]\d+\z/,   'r' => /networkerror/,'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '22' => { 's' => /\A5[.]0[.]\d+\z/,   'r' => /hostunknown/, 'a' => /RFC3464/, 'b' => %r/\A0\z/ },
      '23' => { 's' => /\A5[.]0[.]\d+\z/,   'r' => /mailboxfull/, 'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '24' => { 's' => /\A5[.]0[.]\d+\z/,   'r' => /onhold/,      'a' => /RFC3464/, 'b' => %r/\d\z/ },
      '25' => { 's' => /\A5[.]0[.]\d+\z/,   'r' => /onhold/,      'a' => /RFC3464/, 'b' => %r/\d\z/ },
      '26' => { 's' => /\A5[.]1[.]1\z/,     'r' => /userunknown/, 'a' => /RFC3464/, 'b' => %r/\A0\z/ },
      '27' => { 's' => /\A4[.]4[.]6\z/,     'r' => /networkerror/,'a' => /RFC3464/, 'b' => %r/\A1\z/ },
      '28' => { 's' => /\A2[.]1[.]5\z/,     'r' => /delivered/,   'a' => /RFC3464/, 'b' => %r/\A-1\z/ },
      '29' => { 's' => /\A5[.]5[.]0\z/,     'r' => /syntaxerror/, 'a' => /RFC3464/, 'b' => %r/\A1\z/ },
    },
    'RFC3834' => {
      '01' => { 's' => /\A\z/, 'r' => /vacation/, 'b' => %r/\A-1\z/ },
      '02' => { 's' => /\A\z/, 'r' => /vacation/, 'b' => %r/\A-1\z/ },
      '03' => { 's' => /\A\z/, 'r' => /vacation/, 'b' => %r/\A-1\z/ },
    },
  }

  MTARelative.each_key do |x|
    cn = Module.const_get('Sisimai::' + x)

    describe cn do
      describe '.description' do
        it 'returns String' do
          expect(cn.description).to be_a String
          expect(cn.description.size).to be > 0
        end
      end
      describe '.pattern' do
        it 'returns Hash' do
          expect(cn.pattern).to be_a Hash
          expect(cn.pattern.keys.size).to be > 0
        end
      end
      describe '.scan' do
        it 'returns nil' do
          expect(cn.scan(nil,nil)).to be nil
        end
      end

      (1 .. MTARelative[x].keys.size).each do |i|
        emailfn = sprintf('./set-of-emails/maildir/bsd/%s-%02d.eml', x.downcase, i)
        mailbox = Sisimai::Mail.new(emailfn)
        mailtxt = nil

        n = sprintf('%02d', i)
        next unless mailbox.path
        next unless MTARelative[x][n]

        example sprintf('[%s] %s/mail = %s', n, cn, emailfn) do
          expect(File.exist?(emailfn)).to be true
        end

        while r = mailbox.read do
          mailtxt = r
          it('returns String') { expect(mailtxt).to be_a String }
          p = Sisimai::Message.new(data: r)

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
                expect(e['feedbacktype']).to match(MTARelative['ARF'][n]['f'])
              end
            end

            unless x == 'mFILTER'
              if x == 'RFC3464'
                example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
                  expect(e['agent']).to match(MDAPatterns)
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
                expect(e['status']).to match(/\A(?:[245][.]\d[.]\d+)\z/)
              end
            end

            if e['action'].size > 0
              example sprintf('[%s] %s[action] = %s', n, x, e['action']) do
                expect(e['action']).to match(/\A(?:fail.+|delayed|expired|delivered|deliverable)\z/)
              end
            end

            ['rhost', 'lhost'].each do |ee|
              next unless e[ee]
              next unless e[ee].size > 0
              next if x =~ /\A(?:qmail|Exim|Exchange|X4)/
              example sprintf('[%s] %s[%s] = %s', n, x, ee, e[ee]) do
                expect(e[ee]).to match(/\A(?:localhost|.+[.].+)\z/)
              end
            end
          end

          o = Sisimai::Data.make( data: p, delivered: true )
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
              expect(e.softbounce.to_s).to match(MTARelative[x][n]['b'])
            end

            example sprintf('[%s] %s#replycode = %s', n, x, e.replycode) do
              expect(e.replycode).to match(/\A(?:[245]\d\d|)\z/)
            end

            example sprintf('[%s] %s#timezoneoffset = %s', n, x, e.timezoneoffset) do
              expect(e.timezoneoffset).to match(/\A[-+]\d{4}\z/)
            end

            example sprintf('[%s] %s#deliverystatus = %s', n, x, e.deliverystatus) do
              expect(e.deliverystatus).to match(MTARelative[x][n]['s'])
            end

            example sprintf('[%s] %s#reason = %s', n, x, e.reason) do
              expect(e.reason).to match(MTARelative[x][n]['r'])
            end

            example sprintf('[%s] %s#token = %s', n, x, e.token) do
              expect(e.token).to match(/\A[0-9a-f]{40}\z/)
            end

            if x == 'ARF'
              example sprintf('[%s] %s#feedbacktype = %s', n, x, e.feedbacktype) do
                expect(e.feedbacktype).to match(MTARelative['ARF'][n]['f'])
              end
            end

            %w[deliverystatus diagnostictype smtpcommand lhost rhost alias listid
              action messageid]. each do |ee|
              example sprintf('[%s] %s#%s = %s', n, x, ee, e.send(ee)) do
                expect(e.send(ee)).not_to match(/[ \r]/)
              end
            end

            %w[addresser recipient].each do |ee|
              %w[user host verp alias].each do |eee|
                example sprintf('[%s] %s#%s#%s = %s', n, x, ee, eee, e.send(ee).send(eee)) do
                  expect(e.send(ee).send(eee)).not_to match(/[ \r]/)
                end
              end
            end
          end
        end
      end
    end

  end

end

