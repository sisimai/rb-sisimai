require 'spec_helper'
require 'sisimai/message'

describe Sisimai::Message do
  cn = Sisimai::Message
  sf = './set-of-emails/obsoleted/json-sendgrid-03.json'

  if File.exist?(sf)
    jsonstring = File.open(sf).read
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
      data = { 'email' => '', 'type' => argv['datasrc'] }
      data['email'] = argv['bounces']['email'] || ''
      return data
    end
    messageobj = cn.new(data: jsonobject[0], hook: callbackto, input: 'json')

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

    messageobj = cn.new(
      data: jsonobject[0], 
      hook: callbackto, 
      input: 'json',
      load: ['Sisimai::Neko::Nyaan'],
      order: ['Sisimai::Lhost::AmazonSES', 'Sisimai::Lhost::SendGrid']
    )

    describe '#ds' do
      it('returns Array') { expect(messageobj.ds).to be_a Array }
      messageobj.ds.each do |e|
        example('spec exists') { expect(e.key?('spec')).to be true }
        example('recipient is String') { expect(e['recipient']).to be_a String }
        example('recipient includes "@"') { expect(e['recipient']).to match(/\A.+[@].+[.].+\z/) }
        example('status is String') { expect(e['status']).to match(/\A\d[.]\d[.]\d+\z/) }

        example('date is String') { expect(e['date']).to be_a String }
        example('date size > 0') { expect(e['date'].size).to be > 0 }
        example('diagnosis is String') { expect(e['diagnosis']).to be_a String }
        example('diagnosis size > 0') { expect(e['diagnosis'].size).to be > 0 }
        example('action exists') { expect(e.key?('action')).to be true }
        example('agent is String') { expect(e['agent']).to be_a String }
        example('agent is SendGrid') { expect(e['agent']).to be == 'JSON::SendGrid' }
      end
    end

    describe '#catch' do
      example('type is "json"') { expect(messageobj.catch['type']).to be == 'json' }
      example('"email" key exists') { expect(messageobj.catch.key?('email')).to be true }
    end
  end

end


