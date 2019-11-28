require 'spec_helper'
require 'sisimai'
require 'json'

describe Sisimai do
  samplejsons = [
    'json-amazonses-01.json',
  #   'json-amazonses-02.json',
    'json-amazonses-03.json',
  #   'json-amazonses-04.json',
  #   'json-amazonses-05.json',
    'json-amazonses-06.json',
    'json-sendgrid-01.json',
    'json-sendgrid-02.json',
    'json-sendgrid-03.json',
    'json-sendgrid-04.json',
    'json-sendgrid-05.json',
    'json-sendgrid-06.json',
    'json-sendgrid-07.json',
    'json-sendgrid-08.json',
    'json-sendgrid-09.json',
    'json-sendgrid-10.json',
    'json-sendgrid-11.json',
    'json-sendgrid-12.json',
#   'json-sendgrid-13.json',
    'json-sendgrid-14.json',
    'json-sendgrid-15.json',
    'json-sendgrid-16.json',
    'json-sendgrid-17.json',
  ]

  describe '.make' do
    context 'valid JSON file' do
      samplejsons.each do |e|
        jf = File.open('./set-of-emails/obsoleted/' + e, 'r')
        js = jf.read
        jf.close

        begin
          if RUBY_PLATFORM =~ /java/
            # java-based ruby environment like JRuby.
            require 'jrjackson'
            jo = JrJackson::Json.load(js)
          else
            require 'oj'
            jo = Oj.load(js)
          end
        rescue
          next
        end
        next unless jo

        parseddata = Sisimai.make(jo, input: 'json')
        subject { parseddata }
        it('is Array') { is_expected.to be_a Array }
        it('have data') { expect(parseddata.size).to be > 0 }

        parseddata.each do |ee|
          it 'contains Sisimai::Data' do
            expect(ee).to be_a Sisimai::Data
          end

          describe 'each accessor of Sisimai::Data' do
            example '#timestamp is Sisimai::Time' do
              expect(ee.timestamp).to be_a Sisimai::Time
            end
            example '#addresser is Sisimai::Address' do
              expect(ee.addresser).to be_a Sisimai::Address
            end
            example '#recipient is Sisimai::Address' do
              expect(ee.recipient).to be_a Sisimai::Address
            end

            example '#addresser#address returns String' do
              expect(ee.addresser.address).to be_a String
              expect(ee.addresser.address.size).to be > 0
            end
            example '#recipient#address returns String' do
              expect(ee.recipient.address).to be_a String
              expect(ee.recipient.address.size).to be > 0
            end

            example '#reason returns String' do
              expect(ee.reason).to be_a String
            end
            example '#replycode returns String' do
              expect(ee.replycode).to be_a String
            end
          end

          describe 'each instance method of Sisimai::Data' do
            describe '#damn' do
              damn = ee.damn
              example '#damn returns Hash' do
                expect(damn).to be_a Hash
                expect(damn.each_key.size).to be > 0
              end

              describe 'damned data' do
                example '["addresser"] is #addresser#address' do
                  expect(damn['addresser']).to be == ee.addresser.address
                end
                example '["recipient"] is #recipient#address' do
                  expect(damn['recipient']).to be == ee.recipient.address
                end

                damn.each_key do |eee|
                  next if ee.send(eee).class.to_s =~ /\ASisimai::/
                  next if eee == 'subject'
                  if eee == 'catch'
                    example "['#{eee}'] is ''" do
                      expect(damn[eee]).to be_empty
                    end
                  else
                    example "['#{eee}'] is ##{eee}" do
                      expect(damn[eee]).to be == ee.send(eee)
                    end
                  end
                end
              end
            end

            describe '#dump' do
              dump = ee.dump('json')
              example '#dump returns String' do
                expect(dump).to be_a String
                expect(dump.size).to be > 0
              end
            end
          end

        end

        callbackto = lambda do |argvs|
          data = {
            'type' => argvs['datasrc'],
            'feedbackid' => '',
            'account-id' => '',
            'source-arn' => '',
          }

          if argvs['datasrc'] == 'json'
            return data unless argvs['bounces']
            return data unless argvs['bounces']['mail']
            return data unless argvs['bounces']['bounce']
            data['feedbackid'] = argvs['bounces']['bounce']['feedbackId'] || ''
            data['account-id'] = argvs['bounces']['mail']['sendingAccountId'] || ''
            data['source-arn'] = argvs['bounces']['mail']['sourceArn'] || ''
          end
          return data
        end

        jf = File.open('./set-of-emails/obsoleted/' + e, 'r')
        js = jf.read
        jf.close
        begin
          if RUBY_PLATFORM =~ /java/
            # java-based ruby environment like JRuby.
            jo = JrJackson::Json.load(js)
          else
            jo = Oj.load(js)
          end
        rescue
          next
        end
        next unless jo

        havecaught = Sisimai.make(jo, hook: callbackto, input: 'json')
        havecaught.each do |ee|
          it('is Sisimai::Data') { expect(ee).to be_a Sisimai::Data }
          it('is Hash') { expect(ee.catch).to be_a Hash }
          it('"type" is "json"') { expect(ee.catch['type']).to be == 'json' }
          it('exists "feedbackid" key') { expect(ee.catch.key?('feedbackid')).to be true }
          it('exists "account-id" key') { expect(ee.catch.key?('account-id')).to be true }
          it('exists "source-arn" key') { expect(ee.catch.key?('source-arn')).to be true }
        end

        isntmethod = Sisimai.make(jo, hook: {})
        if isntmethod.is_a? Array
          isntmethod.each do |ee|
            it('is Sisimai::Data') { expect(ee).to be_a Sisimai::Data }
            it('is Nil') { expect(ee.catch).to be_nil }
          end
        end

      end
    end
  end

  describe '.dump' do
    tobetested = %w|addresser recipient senderdomain destination reason timestamp token smtpagent|

    context 'valid JSON file' do
      samplejsons.each do |e|
        jf = File.open('./set-of-emails/obsoleted/' + e, 'r')
        js = jf.read
        jf.close
        begin
          if RUBY_PLATFORM =~ /java/
            # java-based ruby environment like JRuby.
            jo = JrJackson::Json.load(js)
          else
            jo = Oj.load(js)
          end
        rescue
          next
        end
        next unless jo

        jsonstring = Sisimai.dump(jo, input: 'json')
        it('returns String') { expect(jsonstring).to be_a String }
        it('is not empty') { expect(jsonstring.size).to be > 0 }

        describe 'Generate Ruby object from JSON string' do
          rubyobject = JSON.parse(jsonstring)
          it('returns Array') { expect(rubyobject).to be_a Array }

          rubyobject.each do |ee|
            it 'is a flat data structure' do
              expect(ee).to be_a Hash
              expect(ee['addresser']).to be_a ::String
              expect(ee['recipient']).to be_a ::String
              expect(ee['timestamp']).to be_a Integer
            end

            tobetested.each do |eee|
              example("#{eee} = #{ee[eee]}") do
                if eee == 'senderdomain' && ee['addresser'] =~ /\A(?:postmaster|MAILER-DAEMON)\z/
                  expect(ee[eee]).to be_empty
                else
                  expect(ee[eee].size).to be > 0
                end
              end
            end
          end
        end
      end
    end

  end

end

