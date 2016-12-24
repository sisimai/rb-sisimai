require 'spec_helper'
require 'sisimai'

describe 'Sisimai::CED::' do
  PrivateCEDJSONText = {
    'US::SendGrid' => {
      '01001' => %r/(?:userunknown|filtered|mailboxfull)/,
      '01002' => %r/(?:mailboxfull|filtered)/,
      '01003' => %r/userunknown/,
      '01004' => %r/filtered/,
      '01005' => %r/filtered/,
      '01006' => %r/userunknown/,
      '01007' => %r/filtered/,
      '01008' => %r/userunknown/,
      '01009' => %r/userunknown/,
      '01010' => %r/userunknown/,
      '01011' => %r/hostunknown/,
    },
  }

  PrivateCEDJSONText.each_key do |x|
    d0 = './set-of-emails/private/ced-' + x.downcase
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
        next unless e =~ /[.]json\z/

        jsonsrc = sprintf('%s/%s', d0, e)
        jsontxt = File.open(jsonsrc, "r").read
        jsonobj = nil
        bounces = []

        if RUBY_PLATFORM =~ /java/
          # java-based ruby environment like JRuby.
          require 'jrjackson'
          jsonobj = JrJackson::Json.load(jsontxt)
        else
          require 'oj'
          jsonobj = Oj.load(jsontxt)
        end

        if jsonobj.is_a? Array
          bounces = jsonobj
        else
          bounces << jsonobj
        end

        bounces.each do |q|
          sisimai = Sisimai.make(q, input: 'json', delivered: true)
          n = e.sub(/\A(\d+)[-].*[.]json/, '\1')

          example sprintf('[%s] %s has valid regular expression', n, x) do
            expect(PrivateCEDJSONText[x][n]).to be_a Regexp
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
                expect(ee.action).to match(/(?:fail.+|delayed|expired|deliverable)\z/)
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
            end
            example sprintf('[%s] %s#subject = %s', n, x, ee.subject) do
              expect(ee.subject).to be_a String
            end

            example sprintf('[%s] %s#deliverystatus = %s', n, x, ee.deliverystatus) do
              expect(ee.deliverystatus).to be_a String
              unless ee.reason == 'feedback'
                expect(ee.deliverystatus.size).to be > 0
                expect(ee.deliverystatus).to match(/\A[245][.]\d/)
                expect(ee.deliverystatus).not_to match(/[ ]/)
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
              expect(ee.smtpagent).to be == 'CED::' + x
            end

            reason0 = PrivateCEDJSONText[x][n]
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
end

