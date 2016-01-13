require 'spec_helper'
require 'sisimai'
require 'json'

describe Sisimai do
  cn = Sisimai
  bH = 'bounceHammer'

  sampleemail = {
    :mailbox => './set-of-emails/mailbox/mbox-0',
    :maildir => './set-of-emails/maildir/bsd',
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
    subject { cn.version }
    it('is String') { is_expected.to be_a(String) }
    it('is ' + Sisimai::VERSION) { is_expected.to eq Sisimai::VERSION }
  end

  describe '.sysname' do
    subject { cn.sysname }
    it('is String')     { is_expected.to be_a(String) }
    it('returns ' + bH) { is_expected.to match(/bounceHammer/i) }
  end

  describe '.libname' do
    subject { cn.libname }
    it('is String')       { is_expected.to be_a(String) }
    it('returns Sisimai') { expect(cn.libname).to eq 'Sisimai' }
  end

  describe '.make' do
    [:mailbox, :maildir].each do |e|
      mail = cn.make(sampleemail[e])
      subject { mail }
      it('is Array') { is_expected.to be_a Array }
      it('have data') { expect(mail.size).to be > 0 }

      mail.each do |ee|
        example 'each element is Sisimai::Data' do
          expect(ee).to be_a Sisimai::Data
        end
        describe 'each instance method' do
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
            example "['#{eee}'] is ##{eee}" do
              expect(damn[eee]).to be == ee.send(eee)
            end
          end
        end

        dump = ee.dump('json')
        example '#dump returns String' do
          expect(dump).to be_a String
          expect(dump.size).to be > 0
        end

      end
    end

    describe 'non-bounce email' do
      parseddata = cn.make(isnotbounce[:maildir])
      example 'returns nil' do
        expect(parseddata).to be nil
      end
    end

  end

  describe '.dump' do
    tobetested = %w|
      addresser recipient senderdomain destination reason timestamp 
      token smtpagent
    |

    [:mailbox, :maildir].each do |e|
      jsonstring = cn.dump(sampleemail[e])
      example('returns String') { expect(jsonstring).to be_a String }
      example('String is not empty') { expect(jsonstring.size).to be > 0 }

      rubyobject = JSON.parse(jsonstring)
      example('JSON.parse returns Array') { expect(rubyobject).to be_a Array }
      rubyobject.each do |ee|
        example('Element is a Hash') { expect(ee).to be_a Hash }
        tobetested.each do |eee|
          example("#{eee} = #{ee[eee]}") do
            expect(ee[eee].size).to be > 0
          end
        end
      end
    end

    describe 'non-bounce email' do
      jsonstring = cn.dump(isnotbounce[:maildir])
      example 'returns "[]"' do
        expect(jsonstring).to be == '[]'
      end
    end
  end

end
