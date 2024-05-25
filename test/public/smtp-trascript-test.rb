require 'minitest/autorun'
require 'sisimai/smtp/transcript'
require 'sisimai/mail'

class SMTPTranscriptTest < Minitest::Test
  Methods = { class: %w[rise] }
  EmailFp = 'set-of-emails/maildir/bsd/lhost-postfix-75.eml'

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::SMTP::Transcript, e }
  end

  def test_code
    mailobject = Sisimai::Mail.new(EmailFp)
    entiremesg = mailobject.read.sub(/\A.+?\n\n(.+)\z/m, '\1')
    transcript = Sisimai::SMTP::Transcript.rise(entiremesg, 'In:', 'Out:')
    resmtpcomm = %r/(?:CONN|HELO|EHLO|AUTH|MAIL|RCPT|DATA|QUIT|RSET|X[A-Z]+)/;

    assert_instance_of Array, transcript
    assert_equal true, transcript.size > 0

    transcript.each do |e|
      v = e['command']
      assert_match resmtpcomm, v

    end

    ce = assert_raises ArgumentError do
      Sisimai::SMTP::Transcript.rise(nil, nil, nil, nil)
    end
    assert_nil Sisimai::SMTP::Transcript.rise('')

  end

end


