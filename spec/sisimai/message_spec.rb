require 'spec_helper'
require 'sisimai/message'

describe Sisimai::Message do
  cn = Sisimai::Message
  sf = {
    'mail' => './set-of-emails/mailbox/mbox-0',
    'json' => './set-of-emails/jsonapi/ced-us-amazonses-01.json',
  }

  %w|mail json|.each do |q|
    messageobj = nil
    callbackto = nil

    if q == 'mail'
      mailstring = File.open(sf[q]).read
      callbackto = lambda do |argv|
        data = { 'x-mailer' => '', 'return-path' => '' }
        if cv = argv['message'].match(/^X-Mailer:\s*(.+)$/)
            data['x-mailer'] = cv[1]
        end

        if cv = argv['message'].match(/^Return-Path:\s*(.+)$/)
            data['return-path'] = cv[1]
        end
        data['from'] = argv['headers']['from'] || ''
        return data
      end
      messageobj = cn.new(data: mailstring, hook: callbackto, input: 'email')

    else
      jsonstring = File.open(sf[q]).read
      jsonobject = nil

      if RUBY_PLATFORM =~ /java/
        # java-based ruby environment like JRuby.
        require 'jrjackson'
        jsonobject = JrJackson::Json.load(jsonstring)
      else
        require 'oj'
        jsonobject = Oj.load(jsonstring)
      end

      callbackto = lambda do |argv|
        data = { 'feedbackid' => '', 'account-id'  => '', 'source-arn'  => '' }
        data['feedbackid'] = argv['message']['bounce']['feedbackId'] || ''
        data['account-id'] = argv['message']['mail']['sendingAccountId'] || ''
        data['source-arn'] = argv['message']['mail']['sourceArn'] || ''
        return data
      end
      messageobj = cn.new(data: jsonobject, hook: callbackto, input: 'json')
    end

    describe 'class method' do
      describe '.new' do
        it('returns Sisimai::Message object') { expect(messageobj).to be_a cn }
        example('#header returns Hash') { expect(messageobj.header).to be_a Hash }
        example('#ds returns Array') { expect(messageobj.ds).to be_a Array }
        example('#rfc822 returns Hash') { expect(messageobj.rfc822).to be_a Hash }
        example('#from returns String') { expect(messageobj.from).to be_a String }
        example('#catch returns Hash')  { expect(messageobj.catch).to be_a Hash }
      end
    end

    describe 'instance method' do
      describe '#ds' do
        it('returns Array') { expect(messageobj.ds).to be_a Array }
        messageobj.ds.each do |e|
          example('spec is String') { expect(e['spec']).to be_a String }
          example('spec is "SMTP"') { expect(e['spec']).to be == 'SMTP' }
          example('recipient is String') { expect(e['recipient']).to be_a String }
          example('recipient includes "@"') { expect(e['recipient']).to match(/\A.+[@].+[.].+\z/) }
          example('status is String') { expect(e['status']).to match(/\A\d[.]\d[.]\d+\z/) }

          example('date is String') { expect(e['date']).to be_a String }
          example('date size > 0') { expect(e['date'].size).to be > 0 }
          example('diagnosis is String') { expect(e['diagnosis']).to be_a String }
          example('diagnosis size > 0') { expect(e['diagnosis'].size).to be > 0 }
          example('action is String') { expect(e['action']).to be_a String }
          example('action size > 0') { expect(e['action'].size).to be > 0 }
          example('agent is String') { expect(e['agent']).to be_a String }

          if q == 'mail'
            example('command is String') { expect(e['command']).to be_a String }
            example('rhost is String') { expect(e['rhost']).to be_a String }
            example('rhost is a hostname') { expect(e['rhost']).to match(/\A.+[.].+\z/) }
            example('lhost is String') { expect(e['lhost']).to be_a String }
            example('lhost is a hostname') { expect(e['lhost']).to match(/\A.+[.].+\z/) }
            example('agent is Sendmail') { expect(e['agent']).to be == 'MTA::Sendmail' }
          else
            example('agent is AmasonSES') { expect(e['agent']).to be == 'CED::US::AmazonSES' }
          end

        end
      end

      describe '#header' do
        ['content-type', 'to', 'subject', 'date', 'from', 'message-id'].each do |e|
          next unless messageobj.header[e]
          example(e + ' header is String') { expect(messageobj.header[e]).to be_a String }
          example(e + ' header has a size') { expect(messageobj.header[e].size).to be > 0 }
        end
        if q == 'mail'
          example('received header is Array') { expect(messageobj.header['received']).to be_a Array }
        end
      end

      describe '#rfc822' do
        %w|return-path to subject date from message-id|.each do |e|
          next unless messageobj.rfc822[e]
          example(e + ' header is String') { expect(messageobj.rfc822[e]).to be_a String }
          example(e + ' header has a size') { expect(messageobj.rfc822[e].size).to be > 0 }
        end
      end

      describe '#catch' do
        if q == 'mail'
          %w|return-path x-mailer from|.each do |e|
            example(e + 'key exists') { expect(messageobj.catch.key?(e)).to be true }
          end
        else
          %w|feedbackid account-id source-arn|.each do |e|
            example(e + 'key exists') { expect(messageobj.catch.key?(e)).to be true }
          end
        end
      end

    end
  end

end
