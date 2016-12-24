require 'spec_helper'
require 'sisimai/data'
require 'sisimai/mail'
require 'sisimai/message'

describe 'Sisimai::MTA::UserDefined' do
  file = './set-of-emails/mailbox/mbox-1'
  mail = Sisimai::Mail.new(file)

  while r = mail.read do
    mesg = Sisimai::Message.new(data: r, load: ['Sisimai::MTA::UserDefined'])
    data = Sisimai::Data.make(data: mesg)

    describe 'parsed data' do
      example 'Sisimai::Data.make returns Array' do
        expect(data).to be_a Array
      end

      data.each do |e|
        example 'element is Sisimai::Data object' do
          expect(e).to be_a Sisimai::Data
        end

        example('#token returns String') { expect(e.token).to be_a String }
        example('#lhost returns String') { expect(e.lhost).to be_a String }
        example('#rhost returns String') { expect(e.rhost).to be_a String }
        example('#listid returns String') { expect(e.listid).to be_a String }
        example('#messageid returns String') { expect(e.messageid).to be_a String }
        example('#smtpcommand returns String') { expect(e.smtpcommand).to be_a String }

        example('#reason is "userunknown"') { expect(e.reason).to be == 'userunknown' }
        example('#smtpagent is "MTA::UserDefined"') { expect(e.smtpagent).to be == 'MTA::UserDefined' }

        example('#timestamp is Sisimai::Time') { expect(e.timestamp).to be_a Sisimai::Time }
        example('#timestamp#year is 2010') { expect(e.timestamp.year).to be == 2010 }
        example('#timestamp#month is 4') { expect(e.timestamp.month).to be == 4 }
        example('#timestamp#day is 29') { expect(e.timestamp.day).to be == 29 }
        example('#timestamp#wday is 4') { expect(e.timestamp.wday).to be == 4 }

        example('#addresser is Sisimai::Address') { expect(e.addresser).to be_a Sisimai::Address }
        example('#addresser#host returns String') { expect(e.addresser.host).to be_a String }
        example('#addresser#user returns String') { expect(e.addresser.user).to be_a String }
        example('#addresser#address returns String') { expect(e.addresser.address).to be_a String }
        example '#addreser#host is equals to #senderdomain' do
          expect(e.addresser.host).to be == e.senderdomain
        end

        example('#recipient is Sisimai::Address') { expect(e.recipient).to be_a Sisimai::Address }
        example('#recipient#host returns String') { expect(e.recipient.host).to be_a String }
        example('#recipient#user returns String') { expect(e.recipient.user).to be_a String }
        example('#recipient#address returns String') { expect(e.recipient.address).to be_a String }
        example '#addreser#host is equals to #destination' do
          expect(e.recipient.host).to be == e.destination
        end

        example('#subject returns String') { expect(e.subject).to be_a String }
        example('#softbounce returns Integer') { expect(e.softbounce).to be_a Integer }
        example('#diagnosticcode returns String') { expect(e.diagnosticcode).to be_a String }
        example('#diagnostictype returns String') { expect(e.diagnostictype).to be_a String }

        example '#deliverystatus returns String' do
          expect(e.deliverystatus).to be_a String
          expect(e.deliverystatus).to match(/\A\d+[.]\d+[.]\d\z/)
        end

        example '#timezoneoffset returns String' do
          expect(e.timezoneoffset).to be_a String
          expect(e.timezoneoffset).to match(/\A[+-]\d+\z/)
        end

        example '#replycode returns String' do
          expect(e.replycode).to be_a String
          expect(e.replycode).to match(/\A[2345][0-5][0-9]\z/)
        end

        example('#feedbacktype returns String') { expect(e.feedbacktype).to be_a String }
        example('#action returns String') { expect(e.action).to be_a String }
      end

    end

  end
end

