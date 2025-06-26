require 'minitest/autorun'
require 'sisimai/lda'
require 'sisimai/mail'
require 'sisimai/message'

class LDATest < Minitest::Test
  Methods = { class: %w[find] }
  Mailset = {
    "rfc3464-01"       => "mailboxfull",
    "rfc3464-04"       => "systemerror",
    "rfc3464-06"       => "userunknown",
    "lhost-postfix-01" => "mailererror",
    "lhost-qmail-10"   => "suspend",
  }

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::LDA, e }
  end

  def test_find
    assert_empty Sisimai::LDA.find(nil)
    assert_empty Sisimai::LDA.find({"diagnosticcode" => ""})
    assert_empty Sisimai::LDA.find({"diagnosticcode" => "nyaan", "command" => "RCPT"})

    Mailset.each_key do |e|
      mailbox = Sisimai::Mail.new("./set-of-emails/maildir/bsd/" + e + ".eml")
      counter = 0

      while r = mailbox.data.read do
        mesgarg = { data: r }
        message = Sisimai::Message.rise(**mesgarg)

        assert_instance_of Hash, message
        assert_instance_of Array, message["ds"]

        message["ds"].each do |f|
          factobj = { "diagnosticcode" => f["diagnosis"], "command" => f["command"] }
          v = Sisimai::LDA.find(factobj)

          assert_instance_of ::String, v
          assert_equal Mailset[e], v
        end

      end
    end

    ce = assert_raises ArgumentError do
      Sisimai::LDA.find()
      Sisimai::LDA.find(nil, nil)
      Sisimai::LDA.find(nil, nil, nil)
    end
  end
end

