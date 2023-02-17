require 'minitest/autorun'
require 'sisimai/smtp/command'

class SMTPCommandTest < Minitest::Test
  Methods = { class: %w[test find] }
  Strings = {
    'HELO' => [
      'lost connection with mx.example.jp[192.0.2.2] while performing the HELO handshake',
      'SMTP error from remote mail server after HELO mx.example.co.jp:',
    ],
    'EHLO' => [
      'SMTP error from remote mail server after EHLO neko.example.com:',
    ],
    'MAIL' => [
      '452 4.3.2 Connection rate limit exceeded. (in reply to MAIL FROM command)',
      '5.1.8 (Server rejected MAIL FROM address)',
      '5.7.1 Access denied (in reply to MAIL FROM command)',
      'SMTP error from remote mail server after MAIL FROM:<shironeko@example.jp> SIZE=1543:',
    ],
    'RCPT' => [
      '550 5.1.1 <DATA@MAIL.EXAMPLE.JP>... User Unknown  in RCPT TO',
      '550 user unknown (in reply to RCPT TO command)',
      '>>> RCPT To:<mikeneko@example.co.jp>',
      'most progress was RCPT TO response; remote host 192.0.2.32 said: 550 Unknown user MAIL@example.ne.jp',
      'SMTP error from remote mail server after RCPT TO:<kijitora@example.jp>:',
    ],
    'DATA' => [
      'Email rejected per DMARC policy for libsisimai.org (in reply to end of DATA command)',
      'SMTP Server <192.0.2.223> refused to accept your message (DATA), with the following error message',
    ],
  }
  
  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::SMTP::Command, e }
  end

  def test_code
    assert_equal false, Sisimai::SMTP::Command.test("NEKO")
    assert_nil Sisimai::SMTP::Command.test("")
    assert_nil Sisimai::SMTP::Command.find("")

    Strings.each_key do |e|
      assert_match /[A-Z]{4}/, e
      assert_equal true, Sisimai::SMTP::Command.test(e)
      Strings[e].each do |ee|
        cv = Sisimai::SMTP::Command.find(ee)
        assert_instance_of String, cv
        assert_equal e, cv
      end
    end

    ce = assert_raises ArgumentError do
      Sisimai::SMTP::Command.test()
      Sisimai::SMTP::Command.test(nil, nil)
      Sisimai::SMTP::Command.find()
      Sisimai::SMTP::Command.find(nil, nil)
    end
  end
end

