require 'spec_helper'
require 'sisimai/data'
require 'sisimai/mail'
require 'sisimai/message'

describe 'Sisimai::MSP::*' do
  debugOnlyTo = ''
  MSPChildren = {
    'DE::EinsUndEins' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mesgtoobig/, 'b' => %r/\A1\z/ },
    },
    'DE::GMX' => {
      '01' => { 's' => %r/\A5[.]2[.]2\z/,   'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A5[.][12][.][12]\z/, 'r' => %r/(?:userunknown|mailboxfull)/, 'b' => %r/\d\z/ },
      '04' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
    },
    'JP::Biglobe' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
    },
    'JP::EZweb' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/(?:suspend|undefined)/, 'b' => %r/\d\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/suspend/,     'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '05' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '06' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
    },
    'JP::KDDI' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
    },
    'RU::MailRu' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]2[.]2\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.][12][.][12]\z/, 'r' => %r/(?:userunknown|mailboxfull)/, 'b' => %r/\A[01]\z/ },
      '04' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '05' => { 's' => %r/\A5[.]0[.].+\z/, 'r' => %r/notaccept/, 'b' => %r/\A0\z/ },
      '06' => { 's' => %r/\A5[.]0[.].+\z/, 'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
    },
    'RU::Yandex' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.][12][.][12]\z/, 'r' => %r/(?:userunknown|mailboxfull)/, 'b' => %r/\d\z/ },
      '03' => { 's' => %r/\A4[.]4[.]1\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
    },
    'UK::MessageLabs' => {
      '01' => { 's' => %r/\A5[.]0[.]0\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
    },
    'US::AmazonSES' => {
      '01' => { 's' => %r/\A5[.]7[.]1\z/, 'r' => %r/securityerror/, 'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]3[.]0\z/, 'r' => %r/filtered/,      'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]2[.]2\z/, 'r' => %r/mailboxfull/,   'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A5[.]4[.]7\z/, 'r' => %r/expired/,       'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/,   'b' => %r/\A0\z/ },
      '06' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/,   'b' => %r/\A0\z/ },
      '07' => { 's' => %r/\A5[.]7[.]6\z/, 'r' => %r/securityerror/, 'b' => %r/\A1\z/ },
      '08' => { 's' => %r/\A5[.]7[.]9\z/, 'r' => %r/securityerror/, 'b' => %r/\A1\z/ },
    },
    'US::AmazonWorkMail' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]2[.]1\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]3[.]5\z/, 'r' => %r/systemerror/, 'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A5[.]2[.]2\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A4[.]4[.]7\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '06' => { 's' => %r/\A5[.]2[.]2\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '07' => { 's' => %r/\A4[.]4[.]7\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
    },
    'US::Aol' => {
      '01' => { 's' => %r/\A5[.]4[.]4\z/, 'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]2[.]2\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.][12][.][12]\z/, 'r' => %r/(?:mailboxfull|userunknown)/, 'b' => %r/\d\z/ },
      '04' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '05' => { 's' => %r/\A5[.]4[.]4\z/, 'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
      '06' => { 's' => %r/\A5[.]4[.]4\z/, 'r' => %r/notaccept/,   'b' => %r/\A0\z/ },
    },
    'US::Bigfoot' => {
      '01' => { 's' => %r/\A5[.]7[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
    },
    'US::Facebook' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
    },
    'US::Google' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/,   'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/,   'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A5[.]7[.]0\z/,   'r' => %r/filtered/,      'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A5[.]7[.]1\z/,   'r' => %r/blocked/,       'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A5[.]7[.]1\z/,   'r' => %r/securityerror/, 'b' => %r/\A1\z/ },
      '06' => { 's' => %r/\A4[.]2[.]2\z/,   'r' => %r/mailboxfull/,   'b' => %r/\A1\z/ },
      '07' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/systemerror/,   'b' => %r/\A1\z/ },
      '08' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,       'b' => %r/\A1\z/ },
      '09' => { 's' => %r/\A4[.]0[.]\d+\z/, 'r' => %r/expired/,       'b' => %r/\A1\z/ },
      '10' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,       'b' => %r/\A1\z/ },
      '11' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,       'b' => %r/\A1\z/ },
      '12' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/onhold/,        'b' => %r/\d\z/ },
      '13' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,       'b' => %r/\A1\z/ },
      '14' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/,   'b' => %r/\A0\z/ },
      '15' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,       'b' => %r/\A1\z/ },
      '16' => { 's' => %r/\A5[.]2[.]2\z/,   'r' => %r/mailboxfull/,   'b' => %r/\A1\z/ },
      '17' => { 's' => %r/\A4[.]0[.]\d+\z/, 'r' => %r/expired/,       'b' => %r/\A1\z/ },
    },
    'US::GSuite' => {
      '01' => { 's' => %r/\A5[.]1[.]0\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]0[.]0\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A4[.]0[.]0\z/,   'r' => %r/notaccept/,   'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A4[.]0[.]0\z/,   'r' => %r/networkerror/,'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A4[.]0[.]0\z/,   'r' => %r/networkerror/,'b' => %r/\A1\z/ },
      '06' => { 's' => %r/\A4[.]4[.]1\z/,   'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '07' => { 's' => %r/\A4[.]4[.]1\z/,   'r' => %r/expired/,     'b' => %r/\A1\z/ },
    },
    'US::Office365' => {
      '01' => { 's' => %r/\A5[.]1[.]10\z/, 'r' => %r/filtered/,     'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/,  'r' => %r/userunknown/,  'b' => %r/\A0\z/ },
    },
    'US::Outlook' => {
      '01' => { 's' => %r/\A5[.]2[.]2\z/, 'r' => %r/mailboxfull/,   'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/,   'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A5[.]5[.]0\z/, 'r' => %r/hostunknown/,   'b' => %r/\A0\z/ },
      '04' => { 's' => %r/\A5[.][12][.][12]\z/, 'r' => %r/(?:mailboxfull|userunknown)/, 'b' => %r/\A[01]\z/ },
      '05' => { 's' => %r/\A5[.]5[.]0\z/, 'r' => %r/userunknown/,   'b' => %r/\A0\z/ },
      '06' => { 's' => %r/\A4[.]4[.]7\z/, 'r' => %r/expired/,       'b' => %r/\A1\z/ },
      '07' => { 's' => %r/\A4[.]4[.]7\z/, 'r' => %r/expired/,       'b' => %r/\A1\z/ },
    },
    'US::ReceivingSES' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A4[.]0[.]0\z/, 'r' => %r/onhold/,      'b' => %r/\d\z/ },
      '04' => { 's' => %r/\A5[.]2[.]2\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A5[.]3[.]4\z/, 'r' => %r/mesgtoobig/,  'b' => %r/\A1\z/ },
      '06' => { 's' => %r/\A5[.]6[.]1\z/, 'r' => %r/contenterror/,'b' => %r/\A1\z/ },
      '07' => { 's' => %r/\A5[.]2[.]0\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
    },
    'US::SendGrid' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
    },
    'US::Verizon' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
    },
    'US::Yahoo' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]2[.]2\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '04' => { 's' => %r/\A5[.]2[.]2\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A5[.]2[.]1\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
    },
    'US::Zoho' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]2[.][12]\z/,'r' => %r/(?:mailboxfull|filtered)/, 'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A4[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A4[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
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
          next unless debugOnlyTo == sprintf( "msp-%s-%02d", x.downcase, i)
        end

        emailfn = sprintf('./set-of-emails/maildir/bsd/msp-%s-%02d.eml', x.downcase.gsub('::', '-'), i)
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

            example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
              expect(e['agent']).to be == 'MSP::' + x
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
              expect(e.softbounce.to_s).to match(MSPChildren[x][n]['b'])
            end

            example sprintf('[%s] %s#replycode = %s', n, x, e.replycode) do
              expect(e.replycode).to match(/\A(?:[45]\d\d|)\z/)
            end

            example sprintf('[%s] %s#timezoneoffset = %s', n, x, e.timezoneoffset) do
              expect(e.timezoneoffset).to match(/\A[-+]\d{4}\z/)
            end

            example sprintf('[%s] %s#deliverystatus = %s', n, x, e.deliverystatus) do
              expect(e.deliverystatus).to match(MSPChildren[x][n]['s'])
            end

            example sprintf('[%s] %s#reason = %s', n, x, e.reason) do
              expect(e.reason).to match(MSPChildren[x][n]['r'])
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

