require 'minitest/autorun'
require 'sisimai/mda'
require 'sisimai/mail'
require 'sisimai/message'

class MDATest < Minitest::Test
  Methods = { class:  %w[inquire] }
  Mailset = %w[rfc3464-01.eml rfc3464-04.eml rfc3464-06.eml lhost-sendmail-13.eml lhost-qmail-10.eml]
  Message = [
    'Your message to neko was automatically rejected:' << "\n" << 'Not enough disk space',
    'mail.local: Disc quota exceeded',
    'procmail: Quota exceeded while writing',
    'maildrop: maildir over quota.',
    'vdelivermail: user is over quota',
    'vdeliver: Delivery failed due to system quota violation',
  ]

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::Lhost, e }
  end

  def test_inquire
    assert_nil Sisimai::MDA.inquire({}, '')

    Mailset.each do |e|
      mail = Sisimai::Mail.new('./set-of-emails/maildir/bsd/' + e)
      mesg = nil
      head = {}

      while r = mail.data.read do
        args = { data: r }
        mesg = Sisimai::Message.rise(**args)
        head['from'] = mesg['from']

        Message.each do |e|
          cv = Sisimai::MDA.inquire(head, e)

          assert_instance_of Hash, cv
          refute_empty cv['mda']
          refute_empty cv['message']
          assert_equal 'mailboxfull', cv['reason']
        end
      end
    end

    ce = assert_raises ArgumentError do
      Sisimai::MDA.inquire()
      Sisimai::MDA.inquire(nil)
      Sisimai::MDA.inquire(nil, nil, nil)
    end

  end
end

