require 'spec_helper'
require 'sisimai/data'
require 'sisimai/mail'
require 'sisimai/message'

describe 'Sisimai::MSP::*' do
  debugOnlyTo = ''
  MSPChildren = {
    'DE::EinsUndEins' => {
      '01' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/mesgtoobig/ },
    },
    'DE::GMX' => {
      '01' => { 'status' => %r/\A5[.]2[.]2\z/, 'reason' => %r/mailboxfull/ },
      '02' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '03' => { 'status' => %r/\A5[.][12][.][12]\z/, 'reason' => %r/(?:userunknown|mailboxfull)/ },
      '04' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/expired/ },
    },
    'JP::Biglobe' => {
      '01' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/mailboxfull/ },
    },
    'JP::EZweb' => {
      '01' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/filtered/ },
      '02' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/(?:suspend|undefined)/ },
      '03' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/suspend/ },
      '04' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/userunknown/ },
      '05' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/expired/ },
      '06' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/userunknown/ },
    },
    'JP::KDDI' => {
      '01' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/mailboxfull/ },
      '02' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/mailboxfull/ },
      '03' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/mailboxfull/ },
    },
    'RU::MailRu' => {
      '01' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '02' => { 'status' => %r/\A5[.]2[.]2\z/, 'reason' => %r/mailboxfull/ },
      '03' => { 'status' => %r/\A5[.][12][.][12]\z/, 'reason' => %r/(?:userunknown|mailboxfull)/ },
      '04' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
    },
    'RU::Yandex' => {
      '01' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '02' => { 'status' => %r/\A5[.][12][.][12]\z/, 'reason' => %r/(?:userunknown|mailboxfull)/ },
      '03' => { 'status' => %r/\A4[.]4[.]1\z/, 'reason' => %r/expired/ },
    },
    'UK::MessageLabs' => {
      '01' => { 'status' => %r/\A5[.]0[.]0\z/, 'reason' => %r/userunknown/ },
    },
    'US::AmazonSES' => {
      '01' => { 'status' => %r/\A5[.]7[.]1\z/, 'reason' => %r/blocked/ },
      '02' => { 'status' => %r/\A5[.]3[.]0\z/, 'reason' => %r/filtered/ },
      '03' => { 'status' => %r/\A5[.]2[.]2\z/, 'reason' => %r/mailboxfull/ },
      '04' => { 'status' => %r/\A5[.]4[.]7\z/, 'reason' => %r/expired/ },
    },
    'US::AmazonWorkMail' => {
      '01' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '02' => { 'status' => %r/\A5[.]2[.]1\z/, 'reason' => %r/filtered/ },
      '03' => { 'status' => %r/\A5[.]3[.]5\z/, 'reason' => %r/systemerror/ },
      '04' => { 'status' => %r/\A5[.]2[.]2\z/, 'reason' => %r/mailboxfull/ },
      '05' => { 'status' => %r/\A4[.]4[.]7\z/, 'reason' => %r/expired/ },
    },
    'US::Aol' => {
      '01' => { 'status' => %r/\A5[.]4[.]4\z/, 'reason' => %r/hostunknown/ },
      '02' => { 'status' => %r/\A5[.]2[.]2\z/, 'reason' => %r/mailboxfull/ },
      '03' => { 'status' => %r/\A5[.][12][.][12]\z/, 'reason' => %r/(?:mailboxfull|userunknown)/ },
      '04' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
    },
    'US::Bigfoot' => {
      '01' => { 'status' => %r/\A5[.]7[.]1\z/, 'reason' => %r/userunknown/ },
    },
    'US::Facebook' => {
      '01' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/filtered/ },
      '02' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
    },
    'US::Google' => {
      '01' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '02' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '03' => { 'status' => %r/\A5[.]7[.]0\z/, 'reason' => %r/filtered/ },
      '04' => { 'status' => %r/\A5[.]7[.]1\z/, 'reason' => %r/blocked/ },
      '05' => { 'status' => %r/\A5[.]7[.]1\z/, 'reason' => %r/blocked/ },
      '06' => { 'status' => %r/\A4[.]2[.]2\z/, 'reason' => %r/mailboxfull/ },
      '07' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/systemerror/ },
      '08' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/expired/ },
      '09' => { 'status' => %r/\A4[.]0[.]\d+\z/, 'reason' => %r/expired/ },
      '10' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/expired/ },
      '11' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/expired/ },
      '12' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/onhold/ },
      '13' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/expired/ },
      '14' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
    },
    'US::Office365' => {
      '01' => { 'status' => %r/\A5[.]1[.]10\z/, 'reason' => %r/filtered/ },
    },
    'US::Outlook' => {
      '01' => { 'status' => %r/\A5[.]2[.]2\z/, 'reason' => %r/mailboxfull/ },
      '02' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '03' => { 'status' => %r/\A5[.]5[.]0\z/, 'reason' => %r/hostunknown/ },
      '04' => { 'status' => %r/\A5[.][12][.][12]\z/, 'reason' => %r/(?:mailboxfull|userunknown)/ },
      '05' => { 'status' => %r/\A5[.]5[.]0\z/, 'reason' => %r/userunknown/ },
      '06' => { 'status' => %r/\A4[.]4[.]7\z/, 'reason' => %r/expired/ },
      '07' => { 'status' => %r/\A4[.]4[.]7\z/, 'reason' => %r/expired/ },
    },
    'US::ReceivingSES' => {
      '01' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/filtered/ },
      '02' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/filtered/ },
      '03' => { 'status' => %r/\A4[.]0[.]0\z/, 'reason' => %r/onhold/ },
      '04' => { 'status' => %r/\A5[.]2[.]2\z/, 'reason' => %r/mailboxfull/ },
      '05' => { 'status' => %r/\A5[.]3[.]4\z/, 'reason' => %r/mesgtoobig/ },
      '06' => { 'status' => %r/\A5[.]6[.]1\z/, 'reason' => %r/contenterror/ },
      '07' => { 'status' => %r/\A5[.]2[.]0\z/, 'reason' => %r/filtered/ },
    },
    'US::SendGrid' => {
      '01' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '02' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '03' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/expired/ },
    },
    'US::Verizon' => {
      '01' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/userunknown/ },
    },
    'US::Yahoo' => {
      '01' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '02' => { 'status' => %r/\A5[.]2[.]2\z/, 'reason' => %r/mailboxfull/ },
      '03' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '04' => { 'status' => %r/\A5[.]2[.]2\z/, 'reason' => %r/mailboxfull/ },
      '05' => { 'status' => %r/\A5[.]2[.]1\z/, 'reason' => %r/filtered/ },
    },
    'US::Zoho' => {
      '01' => { 'status' => %r/\A5[.]1[.]1\z/, 'reason' => %r/userunknown/ },
      '02' => { 'status' => %r/\A5[.]2[.][12]\z/, 'reason' => %r/(?:mailboxfull|filtered)/ },
      '03' => { 'status' => %r/\A5[.]0[.]\d+\z/, 'reason' => %r/filtered/ },
      '04' => { 'status' => %r/\A4[.]0[.]\d+\z/, 'reason' => %r/expired/ },
      '05' => { 'status' => %r/\A4[.]0[.]\d+\z/, 'reason' => %r/expired/ },
    },
  }

  MSPChildren.each_key do |x|
    cn = Module.const_get('Sisimai::MSP::' + x)

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

      (1 .. MSPChildren[x].keys.size).each do |i|
        if debugOnlyTo.size > 0
          next unless debugOnlyTo == sprintf( "%s-%02d", x.downcase, i)
        end

        emailfn = sprintf('./set-of-emails/maildir/bsd/%s-%02d.eml', x.downcase.gsub('::', '-'), i)
        mailbox = Sisimai::Mail.new(emailfn)
        mailtxt = nil

        n = sprintf('%02d', i)
        next unless mailbox.path
        next unless MSPChildren[x][n]

        example sprintf('[%s] %s/mail = %s', n, cn, emailfn) do
          expect(File.exist?(emailfn)).to be true
        end

        while r = mailbox.read do
          mailtxt = r
          it('returns String') { expect(mailtxt).to be_a String }
          p = Sisimai::Message.new( data: r )

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

            if x == 'MFILTER'
              example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
                expect(e['agent']).to be == 'm-FILTER'
              end
            elsif x == 'X4'
              example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
                expect(e['agent']).to match(/(?:qmail|X4)/)
              end
            elsif x == 'Qmail'
              example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
                expect(e['agent']).to be == 'qmail'
              end
            else
              example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
                expect(e['agent']).to be == x
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

            if e['action']
              example sprintf('[%s] %s[action] = %s', n, x, e['action']) do
                expect(e['action']).to match(/\A(?:fail.+|delayed|expired)\z/)
              end
            end

            ['rhost', 'lhost'].each do |ee|
              next unless e[ee]
              next unless e[ee].size > 0
              next if x =~ /\ARU::MailRu\z/
              example sprintf('[%s] %s[%s] = %s', n, x, ee, e[ee]) do
                expect(e[ee]).to match(/\A(?:localhost|.+[.].+)\z/)
              end
            end
          end

          o = Sisimai::Data.make( data: p )
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
              expect(e.deliverystatus).not_to be_empty
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
              expect(e.deliverystatus).to match(MSPChildren[x][n]['status'])
            end

            example sprintf('[%s] %s#reason = %s', n, x, e.reason) do
              expect(e.reason).to match(MSPChildren[x][n]['reason'])
            end

            example sprintf('[%s] %s#token = %s', n, x, e.token) do
              expect(e.token).to match(/\A[0-9a-f]{40}\z/)
            end

            example sprintf('[%s] %s#feedbacktype = %s', n, x, e.feedbacktype) do
              expect(e.feedbacktype).to be_empty
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

