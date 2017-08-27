require 'spec_helper'
require 'sisimai'
require 'json'

describe Sisimai do
  sampleemail = {
    :mailbox => './set-of-emails/mailbox/mbox-0',
    :maildir => './set-of-emails/maildir/bsd',
    :jsonobj => './set-of-emails/jsonobj/json-amazonses-01.json',
  }
  isnotbounce = {
    :maildir => './set-of-emails/maildir/not',
  }

  describe 'Sisimai::VERSION' do
    subject { Sisimai::VERSION }
    it('returns version') { is_expected.not_to be nil }
    it('returns String' ) { is_expected.to be_a(String) }
    it('matches X.Y.Z'  ) { is_expected.to match(/\A\d[.]\d+[.]\d+/) }
  end

  describe '.version' do
    subject { Sisimai.version }
    it('is String') { is_expected.to be_a(String) }
    it('is ' + Sisimai::VERSION) { is_expected.to eq Sisimai::VERSION }
  end

  describe '.sysname' do
    subject { Sisimai.sysname }
    it('is String')     { is_expected.to be_a(String) }
    it('returns bounceHammer') { is_expected.to match(/bounceHammer/i) }
  end

  describe '.libname' do
    subject { Sisimai.libname }
    it('is String')       { is_expected.to be_a(String) }
    it('returns Sisimai') { expect(Sisimai.libname).to eq 'Sisimai' }
  end

  describe '.make' do
    context 'valid email file' do
      [:mailbox, :maildir, :jsonobj].each do |e|

        if e.to_s == 'jsonobj' 
          jf = File.open(sampleemail[e], 'r')
          js = jf.read
          jf.close

          if RUBY_PLATFORM =~ /java/
            # java-based ruby environment like JRuby.
            require 'jrjackson'
            jsonobject = JrJackson::Json.load(js)
          else
            require 'oj'
            jsonobject = Oj.load(js)
          end
          mail = Sisimai.make(jsonobject, input: 'json')

        else
          mail = Sisimai.make(sampleemail[e], input: 'email')
        end
        subject { mail }
        it('is Array') { is_expected.to be_a Array }
        it('have data') { expect(mail.size).to be > 0 }

        mail.each do |ee|
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

        if e.to_s == 'jsonobj'
          callbackto = lambda do |argv|
            data = { 'feedbackid' => '', 'account-id'  => '', 'source-arn'  => '' }
            data['type'] = argv['datasrc']
            data['feedbackid'] = argv['bounces']['bounce']['feedbackId'] || ''
            data['account-id'] = argv['bounces']['mail']['sendingAccountId'] || ''
            data['source-arn'] = argv['bounces']['mail']['sourceArn'] || ''
            return data
          end

          jf = File.open(sampleemail[e], 'r')
          js = jf.read
          jf.close

          if RUBY_PLATFORM =~ /java/
            # java-based ruby environment like JRuby.
            require 'jrjackson'
            jsonobject = JrJackson::Json.load(js)
          else
            require 'oj'
            jsonobject = Oj.load(js)
          end
          havecaught = Sisimai.make(jsonobject, hook: callbackto, input: 'json')

        else
          callbackto = lambda do |argv|
            data = {
              'x-mailer' => '',
              'return-path' => '',
              'type' => argv['datasrc'],
              'x-virus-scanned' => '',
            }
            if cv = argv['message'].match(/^X-Mailer:\s*(.+)$/)
                data['x-mailer'] = cv[1]
            end

            if cv = argv['message'].match(/^Return-Path:\s*(.+)$/)
                data['return-path'] = cv[1]
            end
            data['from'] = argv['headers']['from'] || ''
            data['x-virus-scanned'] = argv['headers']['x-virus-scanned'] || ''
            return data
          end
          havecaught = Sisimai.make(sampleemail[e],
                                    hook: callbackto,
                                    input: 'email',
                                    field: ['X-Virus-Scanned'])
        end

        havecaught.each do |ee|
          it('is Sisimai::Data') { expect(ee).to be_a Sisimai::Data }
          it('is Hash') { expect(ee.catch).to be_a Hash }

          if e.to_s == 'jsonobj'
            it('"type" is "json"') { expect(ee.catch['type']).to be == 'json' }
            it('exists "feedbackid" key') { expect(ee.catch.key?('feedbackid')).to be true }
            it('exists "account-id" key') { expect(ee.catch.key?('account-id')).to be true }
            it('exists "source-arn" key') { expect(ee.catch.key?('source-arn')).to be true }

          else
            it('"type" is "email"') { expect(ee.catch['type']).to be == 'email' }
            it('exists "x-mailer" key') { expect(ee.catch.key?('x-mailer')).to be true }
            if ee.catch['x-mailer'].size > 0
              it 'matches with X-Mailer' do
                expect(ee.catch['x-mailer']).to match(/[A-Z]/)
              end
            end

            it('exists "return-path" key') { expect(ee.catch.key?('return-path')).to be true }
            if ee.catch['return-path'].size > 0
              it 'matches with Return-Path' do
                expect(ee.catch['return-path']).to match(/(?:<>|.+[@].+|<mailer-daemon>)/i)
              end
            end

            it('exists "from" key') { expect(ee.catch.key?('from')).to be true }
            if ee.catch['from'].size > 0
              it 'matches with From' do
                expect(ee.catch['from']).to match(/(?:<>|.+[@].+|<?mailer-daemon>?)/i)
              end
            end

            it('exists "x-virus-scanned" key') { expect(ee.catch.key?('x-virus-scanned')).to be true }
            if ee.catch['x-virus-scanned'].size > 0
              it 'matches with Clam or Amavis' do
                expect(ee.catch['x-virus-scanned']).to match(/(?:amavis|clam)/i)
              end
            end

          end
        end

        isntmethod = Sisimai.make(sampleemail[e], hook: {})
        if isntmethod.is_a? Array
          isntmethod.each do |ee|
            it('is Sisimai::Data') { expect(ee).to be_a Sisimai::Data }
            it('is Nil') { expect(ee.catch).to be_nil }
          end
        end

      end

    end

    context 'non-bounce email' do
      example 'returns nil' do
        expect(Sisimai.make(isnotbounce[:maildir])).to be nil
        expect(Sisimai.make(nil)).to be nil
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { Sisimai.make }.to raise_error(ArgumentError)
        expect { Sisimai.make(nil, nil) }.to raise_error(ArgumentError)
      end
    end

    context 'Invalid value in arguments' do
      it 'raises RuntimeError' do
        expect { Sisimai.make('/dev/null', field: 'neko') }.to raise_error(RuntimeError)
        expect { Sisimai.make('/dev/null', input: 'neko') }.to raise_error(RuntimeError)
      end
    end
  end

  describe '.dump' do
    tobetested = %w|
      addresser recipient senderdomain destination reason timestamp 
      token smtpagent
    |
    context 'valid email file' do
      [:mailbox, :maildir].each do |e|

        jsonstring = Sisimai.dump(sampleemail[e])
        it('returns String') { expect(jsonstring).to be_a String }
        it('is not empty') { expect(jsonstring.size).to be > 0 }

        describe 'Generate Ruby object from JSON string' do
          rubyobject = JSON.parse(jsonstring)
          it('returns Array') { expect(rubyobject).to be_a Array }

          rubyobject.each do |ee|
            it('contains Hash') { expect(ee).to be_a Hash }
            example('addresser is a String') { expect(ee['addresser']).to be_a ::String }
            example('recipient is a String') { expect(ee['recipient']).to be_a ::String }

            tobetested.each do |eee|
              example("#{eee} = #{ee[eee]}") do
                if eee == 'senderdomain' && ee['addresser'] =~ /\A(?:postmaster|MAILER-DAEMON)\z/
                  expect(ee[eee]).to be_empty
                else
                  if eee == 'senderdomain' && ee['senderdomain'] == ''
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

    context 'non-bounce email' do
      it 'returns "[]"' do
        expect(Sisimai.dump(isnotbounce[:maildir])).to be == '[]'
      end
      it 'returns nil' do
        expect(Sisimai.dump(nil)).to be_nil
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { Sisimai.dump}.to raise_error(ArgumentError)
        expect { Sisimai.dump(nil, nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.engine' do
    it 'returns Hash' do
      expect(Sisimai.engine).to be_a Hash
      expect(Sisimai.engine.keys.size).to be > 0
    end
    it 'including a module information' do
      Sisimai.engine.each do |e, f|
        expect(e).to match(/\ASisimai::/)
        expect(f).to be_a String
        expect(f.size).to be > 0
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { Sisimai.engine(nil)}.to raise_error(ArgumentError)
        expect { Sisimai.engine(nil, nil) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '.reason' do
    it 'returns Hash' do
      expect(Sisimai.reason).to be_a Hash
      expect(Sisimai.reason.keys.size).to be > 0
    end
    it 'including a reason description' do
      Sisimai.reason.each do |e, f|
        expect(e).to match(/\A[A-Z]/)
        expect(f).to be_a String
        expect(f.size).to be > 0
      end
    end

    context 'wrong number of arguments' do
      it 'raises ArgumentError' do
        expect { Sisimai.reason(nil)}.to raise_error(ArgumentError)
        expect { Sisimai.reason(nil, nil) }.to raise_error(ArgumentError)
      end
    end
  end

end
