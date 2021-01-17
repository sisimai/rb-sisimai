require 'minitest/autorun'
require 'sisimai/message'

class MessageTest < Minitest::Test
  Methods = { class:  %w[rise load parse divideup makemap] }
  Mailbox = './set-of-emails/mailbox/mbox-0'
  Fhandle = File.open(Mailbox, 'r')
  Mailtxt = Fhandle.read; Fhandle.close
  Lambda1 = lambda do |argv|
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

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::Message, e }
  end

  def test_rise
    assert_instance_of String, Mailtxt
    assert_equal true, Mailtxt.size > 0

    cv = Sisimai::Message.rise({ data: Mailtxt })
    assert_instance_of Hash,   cv
    assert_instance_of Hash,   cv['header']
    assert_instance_of Array,  cv['ds']
    assert_instance_of Hash,   cv['rfc822']
    assert_instance_of String, cv['from']

    cv = Sisimai::Message.rise({
      data: Mailtxt,
      hook: Lambda1,
      order:[
        'Sisimai::Lhost::Sendmail', 'Sisimai::Lhost::Postfix', 'Sisimai::Lhost::qmail',
        'Sisimai::Lhost::Exchange2003', 'Sisimai::Lhost::Gmail', 'Sisimai::Lhost::Verizon',
      ]
    })

    assert_instance_of Hash,  cv
    assert_instance_of Array, cv['ds']
    assert_instance_of Array, cv['header']['received']
    assert_instance_of Hash,  cv['catch']

    cv['ds'].each do |e|
      assert_equal 'SMTP',    e['spec']
      assert_match /[@]/,     e['recipient']
      assert_equal true,      e.has_key?('command')
      assert_match /\d{4}/,   e['date']
      assert_equal true,      e['diagnosis'].size > 0
      assert_equal true,      e['action'].size > 0
      assert_match /.+[.].+/, e['rhost']
      assert_match /.+[.].+/, e['lhost']
    end

    %w[content-type to subject date from message-id].each { |e| assert_equal true, cv['header'][e].size > 0 }
    %w[return-path to subject date from message-id].each  { |e| assert_equal true, cv['rfc822'][e].size > 0 }

    assert_equal true, cv['catch']['x-mailer'].size > 0
    assert_equal true, cv['catch']['return-path'].size > 0
    assert_equal true, cv['catch']['from'].size > 0

    ce = assert_raises ArgumentError do
      Sisimai::Message.rise(nil)
      Sisimai::Message.rise(nil, nil)
    end

    ce = assert_raises NoMethodError do
      Sisimai::Message.rise()
    end
  end

  def test_load
    assert_instance_of Array, Sisimai::Message.load({})
    ce = assert_raises ArgumentError do
      Sisimai::Message.load()
      Sisimai::Message.load(nil, nil)
    end

  end
end

