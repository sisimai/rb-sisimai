require 'minitest/autorun'
require 'sisimai/mda'
require 'sisimai/mail'
require 'sisimai/message'

class MDATest < Minitest::Test
  Methods = { class:  %w[make] }
  Message = [
    'Your message to neko was automatically rejected:' << "\n" << 'Not enough disk space',
    'mail.local: Disc quota exceeded',
    'procmail: Quota exceeded while writing',
    'maildrop: maildir over quota.',
    'vdelivermail: user is over quota',
    'vdeliver: Delivery failed due to system quota violation',
  ]
  Mailbox = './set-of-emails/maildir/bsd/rfc3464-01.eml'

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::Lhost, e }
  end

  def test_make
    mail = Sisimai::Mail.new(Mailbox)
    mesg = nil
    head = {}

    while r = mail.data.read do
      args = { data: r }
      mesg = Sisimai::Message.rise(**args)
      head['from'] = mesg['from']

      Message.each do |e|
        cv = Sisimai::MDA.make(head, e)

        assert_instance_of Hash, cv
        refute_empty cv['mda']
        refute_empty cv['message']
        assert_equal 'mailboxfull', cv['reason']
      end
    end

    ce = assert_raises ArgumentError do
      Sisimai::MDA.make()
      Sisimai::MDA.make(nil)
      Sisimai::MDA.make(nil, nil, nil)
    end

    ce = assert_raises NoMethodError do
      Sisimai::MDA.make(nil, nil)
    end

  end
end

