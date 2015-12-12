require 'spec_helper'
require 'json'
require 'sisimai/mail'
require 'sisimai/data'
require 'sisimai/data/json'
require 'sisimai/message'

describe Sisimai::Data::JSON do
  cn = Sisimai::Data::JSON
  sf = './eg/maildir-as-a-sample/new/sendmail-02.eml'
  mail = Sisimai::Mail.new(sf)
  list = %w[
    token lhost rhost alias listid reason subject replycode messageid smtpagent
    softbounce smtpcommand diagnosticcode diagnostictype deliverystatus action
    timezoneoffset feedbacktype
  ]

  while r = mail.read do
    mesg = Sisimai::Message.new( { 'data' => r } )
    data = Sisimai::Data.make( { 'data' => mesg } )
    it('returns Array') { expect(data).to be_a Array }

    describe '#dump' do
      data.each do |e|
        json = e.dump('json')
        ruby = JSON.parse(json)

        it('returns JSON') { expect(json).to be_a String }
        example('JSON.parse returns Hash') { expect(ruby).to be_a Hash }

        list.each do |f|
          example "#{f} is #{ruby[f]}" do
            expect(e.send(f)).to be == ruby[f]
          end
        end

        example 'timestamp is ' + ruby['timestamp'].to_s do
          expect(e.timestamp.to_time.to_i).to be == ruby['timestamp']
        end

        example 'addresser is ' + ruby['addresser'] do
          expect(e.addresser.address).to be == ruby['addresser']
        end
        example 'addresser.host is ' + ruby['senderdomain'] do
          expect(e.addresser.host).to be == ruby['senderdomain']
        end

        example 'recipient is ' + ruby['recipient'] do
          expect(e.recipient.address).to be == ruby['recipient']
        end
        example 'recipient.host is ' + ruby['destination'] do
          expect(e.recipient.host).to be == ruby['destination']
        end
      end
    end
  end
end
