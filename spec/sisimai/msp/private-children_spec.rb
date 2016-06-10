require 'spec_helper'
require 'sisimai'

describe 'Sisimai::MSP::' do
  PrivateMSPChildren = {
    'DE::EinsUndEins' => {
      '01001' => %r/undefined/,
      '01002' => %r/undefined/,
    },
    'DE::GMX' => {
      '01001' => %r/expired/,
      '01002' => %r/userunknown/,
      '01003' => %r/mailboxfull/,
      '01004' => %r/(?:userunknown|mailboxfull)/,
    },
    'JP::Biglobe' => {
      '01001' => %r/mailboxfull/,
      '01002' => %r/mailboxfull/,
      '01003' => %r/mailboxfull/,
      '01004' => %r/mailboxfull/,
      '01005' => %r/filtered/,
      '01006' => %r/filtered/,
    },
    'JP::EZweb' => {
      '01001' => %r/userunknown/,
      '01002' => %r/filtered/,
      '01003' => %r/userunknown/,
      '01004' => %r/userunknown/,
      '01005' => %r/suspend/,
      '01006' => %r/filtered/,
      '01007' => %r/suspend/,
      '01008' => %r/filtered/,
      '01009' => %r/filtered/,
      '01010' => %r/filtered/,
      '01011' => %r/filtered/,
      '01012' => %r/filtered/,
      '01013' => %r/expired/,
      '01014' => %r/filtered/,
      '01015' => %r/suspend/,
      '01016' => %r/filtered/,
      '01017' => %r/filtered/,
      '01018' => %r/filtered/,
      '01019' => %r/suspend/,
      '01020' => %r/filtered/,
      '01021' => %r/filtered/,
      '01022' => %r/filtered/,
      '01023' => %r/suspend/,
      '01024' => %r/filtered/,
      '01025' => %r/filtered/,
      '01026' => %r/filtered/,
      '01027' => %r/filtered/,
      '01028' => %r/filtered/,
      '01029' => %r/suspend/,
      '01030' => %r/filtered/,
      '01031' => %r/suspend/,
      '01032' => %r/filtered/,
      '01033' => %r/mailboxfull/,
      '01034' => %r/filtered/,
      '01035' => %r/suspend/,
      '01036' => %r/mailboxfull/,
      '01037' => %r/userunknown/,
      '01038' => %r/suspend/,
      '01039' => %r/suspend/,
      '01040' => %r/suspend/,
      '01041' => %r/suspend/,
      '01042' => %r/suspend/,
      '01043' => %r/suspend/,
      '01044' => %r/userunknown/,
      '01045' => %r/filtered/,
      '01046' => %r/filtered/,
      '01047' => %r/filtered/,
      '01048' => %r/suspend/,
      '01049' => %r/filtered/,
      '01050' => %r/suspend/,
      '01051' => %r/filtered/,
      '01052' => %r/suspend/,
      '01053' => %r/filtered/,
      '01054' => %r/suspend/,
      '01055' => %r/filtered/,
      '01056' => %r/userunknown/,
      '01057' => %r/filtered/,
      '01058' => %r/suspend/,
      '01059' => %r/suspend/,
      '01060' => %r/filtered/,
      '01061' => %r/suspend/,
      '01062' => %r/filtered/,
      '01063' => %r/userunknown/,
      '01064' => %r/filtered/,
      '01065' => %r/suspend/,
      '01066' => %r/filtered/,
      '01067' => %r/filtered/,
      '01068' => %r/suspend/,
      '01069' => %r/suspend/,
      '01070' => %r/suspend/,
      '01071' => %r/filtered/,
      '01072' => %r/suspend/,
      '01073' => %r/filtered/,
      '01074' => %r/filtered/,
      '01075' => %r/suspend/,
      '01076' => %r/filtered/,
      '01077' => %r/expired/,
      '01078' => %r/filtered/,
      '01079' => %r/filtered/,
      '01080' => %r/filtered/,
      '01081' => %r/filtered/,
      '01082' => %r/filtered/,
      '01083' => %r/filtered/,
      '01084' => %r/filtered/,
      '01085' => %r/expired/,
      '01086' => %r/filtered/,
      '01087' => %r/filtered/,
      '01088' => %r/(?:mailboxfull|suspend)/,
      '01089' => %r/filtered/,
      '01090' => %r/suspend/,
      '01091' => %r/filtered/,
      '01092' => %r/filtered/,
      '01093' => %r/suspend/,
      '01094' => %r/userunknown/,
      '01095' => %r/filtered/,
      '01096' => %r/filtered/,
      '01097' => %r/filtered/,
      '01098' => %r/suspend/,
      '01099' => %r/filtered/,
      '01100' => %r/filtered/,
      '01101' => %r/filtered/,
      '01102' => %r/suspend/,
      '01103' => %r/userunknown/,
      '01104' => %r/filtered/,
      '01105' => %r/filtered/,
      '01106' => %r/userunknown/,
      '01107' => %r/filtered/,
      '01108' => %r/userunknown/,
      '01109' => %r/userunknown/,
      '01110' => %r/filtered/,
      '01111' => %r/suspend/,
      '01112' => %r/suspend/,
      '01113' => %r/suspend/,
      '01114' => %r/filtered/,
      '01115' => %r/suspend/,
      '01116' => %r/filtered/,
      '01117' => %r/(?:filtered|suspend)/,
      '01118' => %r/suspend/,
      '01119' => %r/filtered/,
    },
    'JP::KDDI' => {
      '01001' => %r/mailboxfull/,
      '01002' => %r/mailboxfull/,
      '01003' => %r/mailboxfull/,
    },
    'RU::MailRu' => {
      '01001' => %r/userunknown/,
      '01002' => %r/userunknown/,
      '01003' => %r/mailboxfull/,
      '01004' => %r/(?:mailboxfull|userunknown)/,
      '01005' => %r/filtered/,
      '01006' => %r/mailboxfull/,
      '01007' => %r/userunknown/,
      '01008' => %r/userunknown/,
    },
    'RU::Yandex' => {
      '01001' => %r/userunknown/,
      '01002' => %r/(?:userunknown|mailboxfull)/,
    },
    'UK::MessageLabs' => {
      '01001' => %r/userunknown/,
    },
    'US::AmazonSES' => {
      '01001' => %r/mailboxfull/,
      '01002' => %r/filtered/,
      '01003' => %r/userunknown/,
      '01004' => %r/mailboxfull/,
      '01005' => %r/blocked/,
      '01006' => %r/userunknown/,
      '01007' => %r/expired/,
      '01008' => %r/hostunknown/,
      '01009' => %r/userunknown/,
      '01010' => %r/userunknown/,
      '01011' => %r/userunknown/,
      '01012' => %r/userunknown/,
      '01013' => %r/userunknown/,
      '01014' => %r/filtered/,
    },
    'US::AmazonWorkMail' => {
      '01001' => %r/userunknown/,
      '01002' => %r/filtered/,
      '01003' => %r/systemerror/,
      '01004' => %r/mailboxfull/,
      '01005' => %r/expired/,
    },
    'US::Aol' => {
      '01001' => %r/hostunknown/,
      '01002' => %r/mailboxfull/,
      '01003' => %r/(?:mailboxfull|userunknown)/,
      '01004' => %r/(?:mailboxfull|userunknown)/,
      '01005' => %r/userunknown/,
      '01006' => %r/userunknown/,
      '01007' => %r/mailboxfull/,
      '01008' => %r/filtered/,
      '01009' => %r/blocked/,
      '01010' => %r/filtered/,
      '01011' => %r/filtered/,
      '01012' => %r/mailboxfull/,
      '01013' => %r/mailboxfull/,
      '01014' => %r/userunknown/,
    },
    'US::Bigfoot' => {
      '01001' => %r/spamdetected/,
    },
    'US::Facebook' => {
      '01001' => %r/filtered/,
    },
    'US::Google' => {
      '01001' => %r/expired/,
      '01002' => %r/suspend/,
      '01003' => %r/expired/,
      '01004' => %r/filtered/,
      '01005' => %r/expired/,
      '01006' => %r/filtered/,
      '01007' => %r/userunknown/,
      '01008' => %r/expired/,
      '01009' => %r/expired/,
      '01010' => %r/userunknown/,
      '01011' => %r/mailboxfull/,
      '01012' => %r/expired/,
      '01013' => %r/mailboxfull/,
      '01014' => %r/userunknown/,
      '01015' => %r/filtered/,
      '01016' => %r/filtered/,
      '01017' => %r/filtered/,
      '01018' => %r/userunknown/,
      '01019' => %r/userunknown/,
      '01020' => %r/userunknown/,
      '01021' => %r/userunknown/,
      '01022' => %r/userunknown/,
      '01023' => %r/userunknown/,
      '01024' => %r/blocked/,
      '01025' => %r/filtered/,
      '01026' => %r/filtered/,
      '01027' => %r/blocked/,
      '01028' => %r/systemerror/,
      '01029' => %r/onhold/,
      '01030' => %r/blocked/,
      '01031' => %r/blocked/,
      '01032' => %r/expired/,
      '01033' => %r/blocked/,
      '01034' => %r/expired/,
      '01035' => %r/expired/,
      '01036' => %r/expired/,
      '01037' => %r/blocked/,
      '01038' => %r/userunknown/,
      '01039' => %r/userunknown/,
      '01040' => %r/(?:expired|undefined)/,
      '01041' => %r/userunknown/,
      '01042' => %r/userunknown/,
      '01043' => %r/userunknown/,
      '01044' => %r/securityerror/,
      '01045' => %r/expired/,
    },
    'US::Office365' => {
      '01001' => %r/filtered/,
      '01002' => %r/filtered/,
      '01003' => %r/filtered/,
      '01004' => %r/filtered/,
      '01005' => %r/filtered/,
      '01006' => %r/networkerror/,
    },
    'US::Outlook' => {
      '01002' => %r/userunknown/,
      '01003' => %r/userunknown/,
      '01007' => %r/blocked/,
      '01008' => %r/mailboxfull/,
      '01016' => %r/mailboxfull/,
      '01017' => %r/userunknown/,
      '01018' => %r/hostunknown/,
      '01019' => %r/(?:userunknown|mailboxfull)/,
      '01023' => %r/userunknown/,
      '01024' => %r/userunknown/,
      '01025' => %r/filtered/,
      '01026' => %r/filtered/,
    },
    'US::SendGrid' => {
      '01001' => %r/userunknown/,
      '01002' => %r/userunknown/,
      '01003' => %r/expired/,
      '01004' => %r/filtered/,
      '01005' => %r/userunknown/,
      '01006' => %r/mailboxfull/,
      '01007' => %r/userunknown/,
      '01008' => %r/filtered/,
      '01009' => %r/userunknown/,
    },
    'US::Verizon' => {
      '01001' => %r/userunknown/,
      '01002' => %r/userunknown/,
    },
    'US::Yahoo' => {
      '01001' => %r/userunknown/,
      '01002' => %r/mailboxfull/,
      '01003' => %r/filtered/,
      '01004' => %r/userunknown/,
    },
    'US::Zoho' => {
      '01001' => %r/userunknown/,
      '01002' => %r/(?:filtered|mailboxfull)/,
      '01003' => %r/filtered/,
      '01004' => %r/expired/,
    },
  }

  PrivateMSPChildren.each_key do |x|
    d0 = './set-of-emails/private/' + x.downcase
    d0 = d0.gsub(/::/, '-')
    next unless Dir.exist?(d0)

    describe x do
      example 'directory exists' do
        expect(Dir.exist?(d0)).to be true
      end

      dhandle = Dir.open(d0)
      while e = dhandle.read do
        next if e == '.'
        next if e == '..'

        emailfn = sprintf('%s/%s', d0, e)
        sisimai = Sisimai.make(emailfn)
        n = e.sub(/\A(\d+)[-].*[.]eml/, '\1')

        example sprintf('[%s] %s has valid regular expression', n, x) do
          expect(PrivateMSPChildren[x][n]).to be_a Regexp
        end

        example sprintf('[%s] %s have 1 or more element', n, x) do
          expect(sisimai).to be_a Array
          expect(sisimai.size).to be > 0
        end
        next unless sisimai

        sisimai.each do |ee|
          it 'is Sisimai::Data object' do
            expect(ee).to be_a Sisimai::Data
          end

          example sprintf('[%s] %s#token = %s', n, x, ee.token) do
            expect(ee.token).to be_a String
            expect(ee.token.size).to be > 0
          end
          example sprintf('[%s] %s#lhost = %s', n, x, ee.lhost) do
            expect(ee.lhost).to be_a String
            expect(ee.lhost).not_to match(/[ ]/)
          end
          example sprintf('[%s] %s#rhost = %s', n, x, ee.rhost) do
            expect(ee.rhost).to be_a String
            expect(ee.rhost).not_to match(/[ ]/)
          end
          example sprintf('[%s] %s#alias = %s', n, x, ee.alias) do
            expect(ee.alias).to be_a String
            expect(ee.alias).not_to match(/[ ]/)
          end
          example sprintf('[%s] %s#listid = %s', n, x, ee.listid) do
            expect(ee.listid).to be_a String
            expect(ee.listid).not_to match(/[ ]/)
          end
          example sprintf('[%s] %s#action = %s', n, x, ee.action) do
            expect(ee.action).to be_a String
            expect(ee.action).not_to match(/[ ]/)
            if ee.action.size > 0
              expect(ee.action).to match(/(?:fail.+|delayed|expired)\z/)
            end
          end
          example sprintf('[%s] %s#messageid = %s', n, x, ee.messageid) do
            expect(ee.messageid).to be_a String
            expect(ee.messageid).not_to match(/[ ]/)
          end
          example sprintf('[%s] %s#smtpcommand = %s', n, x, ee.smtpcommand) do
            expect(ee.smtpcommand).to be_a String
            expect(ee.smtpcommand).not_to match(/[ ]/)
          end
          example sprintf('[%s] %s#diagnosticcode = %s', n, x, ee.diagnosticcode) do
            expect(ee.diagnosticcode).to be_a String
          end
          example sprintf('[%s] %s#replycode = %s', n, x, ee.replycode) do
            expect(ee.replycode).to be_a String
            expect(ee.replycode).to match(/\A(?:[45]\d\d|)\z/)
          end

          example sprintf('[%s] %s#feedbacktype = %s', n, x, ee.feedbacktype) do
            expect(ee.feedbacktype).to be_a String
          end
          example sprintf('[%s] %s#subject = %s', n, x, ee.subject) do
            expect(ee.subject).to be_a String
          end

          example sprintf('[%s] %s#deliverystatus = %s', n, x, ee.deliverystatus) do
            expect(ee.deliverystatus).to be_a String
            expect(ee.deliverystatus.size).to be > 0
            expect(ee.deliverystatus).to match(/\A[45][.]\d/)
            expect(ee.deliverystatus).not_to match(/[ ]/)
          end

          example sprintf('[%s] %s#softbounce = %s', n, x, ee.softbounce) do
            expect(ee.softbounce).to be_a Integer
            expect(ee.softbounce.between?(-1,1)).to be true
            if ee.deliverystatus.size > 0
              if ee.deliverystatus[0,1] == "4"
                expect(ee.softbounce).to be == 1
              elsif ee.deliverystatus[0,1] == "5"
                expect(ee.softbounce).to be == 0
              else
                expect(ee.softbounce).to be == -1
              end
            else
              expect(ee.softbounce).to be == -1
            end
          end

          example sprintf('[%s] %s#smtpagent = %s', n, x, ee.smtpagent) do
            expect(ee.smtpagent).to be_a String
            expect(ee.smtpagent.size).to be > 0
            expect(ee.smtpagent).to be == x
          end

          reason0 = PrivateMSPChildren[x][n]
          example sprintf('[%s] %s#reason = %s', n, x, ee.reason) do
            expect(ee.reason).to be_a String
            expect(ee.reason.size).to be > 0
            expect(ee.reason).to match reason0
          end

          example sprintf('[%s] %s#timezoneoffset = %s', n, x, ee.timezoneoffset) do
            expect(ee.timezoneoffset).to be_a String
            expect(ee.timezoneoffset).to match(/\A[+-]\d+\z/)
          end

          example sprintf('[%s] %s#timestamp = %s', n, x, ee.timestamp) do
            expect(ee.timestamp).to be_a Sisimai::Time
            expect(ee.timestamp.year.between?(1982,2100)).to be true
            expect(ee.timestamp.month.between?(1,12)).to be true
            expect(ee.timestamp.day.between?(1,31)).to be true
            expect(ee.timestamp.wday.between?(0,6)).to be true
          end

          example sprintf('[%s] %s#addresser = %s', n, x, ee.addresser) do
            expect(ee.addresser).to be_a Sisimai::Address
            expect(ee.addresser.host).to be_a String
            expect(ee.addresser.host.size).to be > 0
            expect(ee.addresser.host).not_to match(/[ ]/)
            expect(ee.addresser.host).to be == ee.senderdomain

            expect(ee.addresser.user).to be_a String
            expect(ee.addresser.user.size).to be > 0
            expect(ee.addresser.user).not_to match(/[ ]/)

            expect(ee.addresser.address).to be_a String
            expect(ee.addresser.address.size).to be > 0
            expect(ee.addresser.address).not_to match(/[ ]/)

            expect(ee.addresser.verp).to be_a String
            expect(ee.addresser.verp).not_to match(/[ ]/)

            expect(ee.addresser.alias).to be_a String
            expect(ee.addresser.alias).not_to match(/[ ]/)
          end

          example sprintf('[%s] %s#recipient = %s', n, x, ee.recipient) do
            expect(ee.recipient).to be_a Sisimai::Address
            expect(ee.recipient.host).to be_a String
            expect(ee.recipient.host.size).to be > 0
            expect(ee.recipient.host).not_to match(/[ ]/)
            expect(ee.recipient.host).to be == ee.destination

            expect(ee.recipient.user).to be_a String
            expect(ee.recipient.user.size).to be > 0
            expect(ee.recipient.user).not_to match(/[ ]/)

            expect(ee.recipient.address).to be_a String
            expect(ee.recipient.address.size).to be > 0
            expect(ee.recipient.address).not_to match(/[ ]/)

            expect(ee.recipient.verp).to be_a String
            expect(ee.recipient.verp).not_to match(/[ ]/)

            expect(ee.recipient.alias).to be_a String
            expect(ee.recipient.alias).not_to match(/[ ]/)
          end

        end

      end

    end
  end
end


