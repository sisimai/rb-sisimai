require 'spec_helper'
require 'sisimai'

describe 'Sisimai::' do
  DeliveryAgentNames = %r/\A(?:dovecot|mail[.]local|procmail|maildrop|vpopmail|vmailmgr|RFC3464)/
  PrivateMTARelative = {
    'ARF' => {
      '01001' => %r/feedback/,
      '01002' => %r/feedback/,
      '01003' => %r/feedback/,
      '01004' => %r/feedback/,
      '01005' => %r/feedback/,
      '01006' => %r/feedback/,
      '01007' => %r/feedback/,
      '01008' => %r/feedback/,
      '01009' => %r/feedback/,
      '01010' => %r/feedback/,
      '01011' => %r/feedback/,
      '01012' => %r/feedback/,
      '01013' => %r/feedback/,
      '01014' => %r/feedback/,
      '01015' => %r/feedback/,
    },
    'RFC3464' => {
      '01001' => %r/expired/,
      '01002' => %r/userunknown/,
      '01003' => %r/mesgtoobig/,
      '01004' => %r/filtered/,
      '01005' => %r/networkerror/,
      '01007' => %r/onhold/,
      '01008' => %r/expired/,
      '01009' => %r/userunknown/,
      '01011' => %r/hostunknown/,
      '01013' => %r/filtered/,
      '01014' => %r/userunknown/,
      '01015' => %r/hostunknown/,
      '01016' => %r/userunknown/,
      '01017' => %r/userunknown/,
      '01018' => %r/mailboxfull/,
      '01019' => %r/filtered/,
      '01020' => %r/userunknown/,
      '01021' => %r/filtered/,
      '01022' => %r/userunknown/,
      '01023' => %r/filtered/,
      '01024' => %r/userunknown/,
      '01025' => %r/filtered/,
      '01026' => %r/filtered/,
      '01027' => %r/filtered/,
      '01029' => %r/filtered/,
      '01031' => %r/userunknown/,
      '01033' => %r/userunknown/,
      '01035' => %r/userunknown/,
      '01036' => %r/filtered/,
      '01037' => %r/systemerror/,
      '01038' => %r/filtered/,
      '01039' => %r/hostunknown/,
      '01040' => %r/networkerror/,
      '01041' => %r/filtered/,
      '01042' => %r/filtered/,
      '01043' => %r/(?:filtered|onhold)/,
      '01044' => %r/userunknown/,
      '01045' => %r/userunknown/,
      '01046' => %r/userunknown/,
      '01047' => %r/undefined/,
      '01048' => %r/filtered/,
      '01049' => %r/userunknown/,
      '01050' => %r/filtered/,
      '01051' => %r/userunknown/,
      '01052' => %r/undefined/,
      '01053' => %r/mailererror/,
      '01054' => %r/undefined/,
      '01055' => %r/filtered/,
      '01056' => %r/mailboxfull/,
      '01057' => %r/filtered/,
      '01058' => %r/undefined/,
      '01059' => %r/userunknown/,
      '01060' => %r/filtered/,
      '01061' => %r/hasmoved/,
      '01062' => %r/userunknown/,
      '01063' => %r/filtered/,
      '01064' => %r/filtered/,
      '01065' => %r/spamdetected/,
      '01066' => %r/filtered/,
      '01067' => %r/systemerror/,
      '01068' => %r/undefined/,
      '01069' => %r/expired/,
      '01070' => %r/userunknown/,
      '01071' => %r/mailboxfull/,
      '01072' => %r/filtered/,
      '01073' => %r/filtered/,
      '01074' => %r/filtered/,
      '01075' => %r/filtered/,
      '01076' => %r/systemerror/,
      '01077' => %r/filtered/,
      '01078' => %r/userunknown/,
      '01079' => %r/filtered/,
      '01081' => %r/(?:filtered|syntaxerror)/,
      '01083' => %r/filtered/,
      '01085' => %r/filtered/,
      '01086' => %r/(?:filtered|delivered)/,
      '01087' => %r/filtered/,
      '01088' => %r/onhold/,
      '01089' => %r/filtered/,
      '01090' => %r/filtered/,
      '01091' => %r/undefined/,
      '01092' => %r/undefined/,
      '01093' => %r/filtered/,
      '01095' => %r/filtered/,
      '01096' => %r/filtered/,
      '01097' => %r/filtered/,
      '01098' => %r/filtered/,
      '01099' => %r/securityerror/,
      '01100' => %r/securityerror/,
      '01101' => %r/filtered/,
      '01102' => %r/filtered/,
      '01103' => %r/expired/,
      '01104' => %r/filtered/,
      '01105' => %r/filtered/,
      '01106' => %r/expired/,
      '01107' => %r/filtered/,
      '01108' => %r/undefined/,
      '01109' => %r/onhold/,
      '01111' => %r/mailboxfull/,
      '01112' => %r/filtered/,
      '01113' => %r/filtered/,
      '01114' => %r/systemerror/,
      '01115' => %r/expired/,
      '01116' => %r/mailboxfull/,
      '01117' => %r/mesgtoobig/,
      '01118' => %r/expired/,
      '01120' => %r/filtered/,
      '01121' => %r/expired/,
      '01122' => %r/filtered/,
      '01123' => %r/expired/,
      '01124' => %r/mailererror/,
      '01125' => %r/networkerror/,
      '01126' => %r/userunknown/,
      '01127' => %r/filtered/,
      '01128' => %r/(?:systemerror|onhold)/,
      '01129' => %r/userunknown/,
      '01130' => %r/systemerror/,
      '01131' => %r/userunknown/,
      '01132' => %r/systemerror/,
      '01133' => %r/systemerror/,
      '01134' => %r/filtered/,
      '01135' => %r/userunknown/,
      '01136' => %r/undefined/,
      '01137' => %r/spamdetected/,
      '01138' => %r/userunknown/,
      '01139' => %r/expired/,
      '01140' => %r/filtered/,
      '01141' => %r/userunknown/,
      '01142' => %r/filtered/,
      '01143' => %r/undefined/,
      '01144' => %r/filtered/,
      '01145' => %r/mailboxfull/,
      '01146' => %r/mailboxfull/,
      '01148' => %r/mailboxfull/,
      '01149' => %r/expired/,
      '01150' => %r/mailboxfull/,
      '01151' => %r/exceedlimit/,
      '01152' => %r/exceedlimit/,
      '01153' => %r/onhold/,
      '01154' => %r/userunknown/,
      '01155' => %r/networkerror/,
      '01156' => %r/spamdetected/,
      '01157' => %r/filtered/,
      '01158' => %r/(?:expired|onhold)/,
      '01159' => %r/mailboxfull/,
      '01160' => %r/filtered/,
      '01161' => %r/mailererror/,
      '01162' => %r/filtered/,
      '01163' => %r/mesgtoobig/,
      '01164' => %r/userunknown/,
      '01165' => %r/networkerror/,
      '01166' => %r/systemerror/,
      '01167' => %r/hostunknown/,
      '01168' => %r/mailboxfull/,
      '01169' => %r/userunknown/,
      '01170' => %r/onhold/,
      '01171' => %r/onhold/,
      '01172' => %r/mailboxfull/,
      '01173' => %r/networkerror/,
      '01174' => %r/expired/,
      '01175' => %r/filtered/,
      '01176' => %r/filtered/,
      '01177' => %r/(?:filtered|onhold)/,
      '01178' => %r/filtered/,
      '01179' => %r/userunknown/,
      '01180' => %r/mailboxfull/,
      '01181' => %r/filtered/,
      '01182' => %r/onhold/,
      '01183' => %r/mailboxfull/,
      '01184' => %r/(?:undefined|onhold)/,
      '01185' => %r/networkerror/,
      '01186' => %r/networkerror/,
      '01187' => %r/userunknown/,
      '01188' => %r/userunknown/,
      '01189' => %r/userunknown/,
      '01190' => %r/userunknown/,
      '01191' => %r/userunknown/,
      '01192' => %r/userunknown/,
      '01193' => %r/userunknown/,
      '01194' => %r/userunknown/,
      '01195' => %r/norelaying/,
      '01196' => %r/userunknown/,
      '01197' => %r/userunknown/,
      '01198' => %r/userunknown/,
      '01199' => %r/userunknown/,
      '01200' => %r/userunknown/,
      '01201' => %r/userunknown/,
      '01202' => %r/userunknown/,
      '01203' => %r/userunknown/,
      '01204' => %r/userunknown/,
      '01205' => %r/userunknown/,
      '01206' => %r/userunknown/,
      '01207' => %r/securityerror/,
      '01208' => %r/userunknown/,
      '01209' => %r/userunknown/,
      '01210' => %r/userunknown/,
      '01211' => %r/userunknown/,
      '01212' => %r/mailboxfull/,
      '01213' => %r/spamdetected/,
      '01214' => %r/spamdetected/,
      '01215' => %r/spamdetected/,
      '01216' => %r/onhold/,
      '01217' => %r/userunknown/,
      '01218' => %r/mailboxfull/,
      '01219' => %r/onhold/,
      '01220' => %r/filtered/,
      '01221' => %r/filtered/,
      '01222' => %r/mailboxfull/,
      '01223' => %r/mailboxfull/,
      '01224' => %r/filtered/,
      '01225' => %r/expired/,
      '01226' => %r/filtered/,
      '01227' => %r/userunknown/,
      '01228' => %r/onhold/,
      '01229' => %r/filtered/,
      '01230' => %r/filtered/,
      '01231' => %r/filtered/,
      '01232' => %r/networkerror/,
      '01233' => %r/mailererror/,
      '01234' => %r/(?:filtered|onhold)/,
      '01235' => %r/filtered/,
      '01236' => %r/userunknown/,
      '01237' => %r/userunknown/,
      '01238' => %r/userunknown/,
      '01239' => %r/userunknown/,
      '01240' => %r/userunknown/,
      '01241' => %r/userunknown/,
      '01242' => %r/userunknown/,
      '01243' => %r/syntaxerror/,
      '01244' => %r/mailboxfull/,
      '01245' => %r/mailboxfull/,
      '01246' => %r/userunknown/,
      '01247' => %r/userunknown/,
      '01248' => %r/mailboxfull/,
      '01249' => %r/syntaxerror/,
      '01250' => %r/mailboxfull/,
      '01251' => %r/mailboxfull/,
      '01252' => %r/networkerror/,
      '01253' => %r/hostunknown/,
    },
    'RFC3834' => {
      '01002' => %r/vacation/,
    },
  }

  PrivateMTARelative.each_key do |x|
    d0 = './set-of-emails/private/' + x.downcase
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
        sisimai = Sisimai.make(emailfn, delivered: true)
        n = e.sub(/\A(\d+)[-].*[.]eml/, '\1')

        example sprintf('[%s] %s has valid regular expression', n, x) do
          expect(PrivateMTARelative[x][n]).to be_a Regexp
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
              expect(ee.action).to match(/(?:fail.+|delayed|expired|delivered|deliverable|relayed)\z/)
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
            expect(ee.replycode).to match(/\A(?:[245]\d\d|)\z/)
          end

          example sprintf('[%s] %s#feedbacktype = %s', n, x, ee.feedbacktype) do
            expect(ee.feedbacktype).to be_a String
            if x == 'ARF'
              expect(ee.feedbacktype).not_to be_empty
            end
          end

          example sprintf('[%s] %s#subject = %s', n, x, ee.subject) do
            expect(ee.subject).to be_a String
          end

          example sprintf('[%s] %s#deliverystatus = %s', n, x, ee.deliverystatus) do
            expect(ee.deliverystatus).to be_a String
            expect(ee.deliverystatus).not_to match(/[ ]/)
            if x != 'ARF' && x != 'RFC3834' 
              expect(ee.deliverystatus.size).to be > 0
              expect(ee.deliverystatus).to match(/\A[245][.]\d/)
            end
          end

          example sprintf('[%s] %s#softbounce = %s', n, x, ee.softbounce) do
            expect(ee.softbounce).to be_a Integer
            expect(ee.softbounce.between?(-1,1)).to be true
            if ee.reason =~ /(?:feedback|vacation|delivered)/
              expect(ee.softbounce).to be == -1
            elsif ee.reason =~ /(?:unknown|hasmoved)/
              expect(ee.softbounce).to be == 0
            else
              expect(ee.softbounce.to_s).to match(/[01]/)
            end
          end

          example sprintf('[%s] %s#smtpagent = %s', n, x, ee.smtpagent) do
            expect(ee.smtpagent).to be_a String
            expect(ee.smtpagent.size).to be > 0
            if x == 'RFC3464'
              expect(ee.smtpagent).to match DeliveryAgentNames
            else
              if x != 'ARF'
                expect(ee.smtpagent).to be == x
              end
            end
          end

          reason0 = PrivateMTARelative[x][n]
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


