require 'minitest/autorun'
require 'sisimai/string'

class StringTest < Minitest::Test
  Methods = { class: %w[token is_8bit sweep aligned to_plain to_utf8] }

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::String, e }
  end

  Es = 'envelope-sender@example.jp'
  Er = 'envelope-recipient@example.org'
  Ts = '239aa35547613b2fa94f40c7f35f4394e99fdd88'
  Fr = 'Final-Recipient: rfc822; <neko@example.jp>'

  def test_token
    cv = Sisimai::String.token(Es, Er, 1)
    assert_instance_of String, cv
    assert_equal           Ts, cv

    assert_nil Sisimai::String.token('', '', 0)
    assert_nil Sisimai::String.token(Es, '', 0)
    assert_nil Sisimai::String.token('', Er, 0)
    assert_nil Sisimai::String.token(Es, Er, nil)

    ce = assert_raises ArgumentError do
      Sisimai::String.token()
      Sisimai::String.token(Es)
      Sisimai::String.token(Es, Er)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_is_8bit
    assert_equal true,  Sisimai::String.is_8bit('ニャーン')
    assert_equal false, Sisimai::String.is_8bit('Nyaaaaan')
    assert_nil          Sisimai::String.is_8bit(nil)

    ce = assert_raises ArgumentError do
      Sisimai::String.is_8bit()
      Sisimai::String.is_8bit("", "")
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_sweep
    assert_nil                 Sisimai::String.sweep(nil)
    assert_equal 'neko nyaan', Sisimai::String.sweep('   neko nyaan  ')
    assert_equal 'nekochan !', Sisimai::String.sweep('   nekochan   !')

    ce = assert_raises ArgumentError do
      Sisimai::String.sweep()
      Sisimai::String.sweep("", "")
    end
    assert_match /wrong number of arguments/, ce.to_s
  end

  def test_aligned
    assert_nil          Sisimai::String.aligned(nil, nil)
    assert_equal true,  Sisimai::String.aligned(Fr, ['rfc822', ' <', '@', '>'])
    assert_equal false, Sisimai::String.aligned(Fr, ['rfc822', '<<', ' ', '>'])

    ce = assert_raises ArgumentError do
      Sisimai::String.aligned()
      Sisimai::String.aligned(nil)
      Sisimai::String.aligned("nekochan", [], 1)
    end
  end

  def test_ipv4
    ip4address = [
      ['host smtp.example.jp 127.0.0.4 SMTP error from remote mail server', '127.0.0.4'],
      ['mx.example.jp (192.0.2.2) reason: 550 5.2.0 Mail rejete.', '192.0.2.2'],
      ['Client host [192.0.2.49] blocked using cbl.abuseat.org (state 13).', '192.0.2.49'],
      ['127.0.0.1', '127.0.0.1'],
      ['365.31.7.1', ''],
      ['a.b.c.d', ''],
    ]
    ip4address.each do |e|
      assert_equal e[1], Sisimai::String.ipv4(e[0]).shift.to_s
    end

    ce = assert_raises ArgumentError do
      Sisimai::String.ipv4()
      Sisimai::String.ipv4("nekochan", nil)
    end
  end

  Ht1 = '
        <html>
        <head>
        </head>
        <body>
            <h1>neko</h1>
            <div>
            <a href = "http://libsisimai.org">Sisimai</a>
            <a href = "mailto:maketest@libsisimai.org">maketest</a>
            </div>
        </body>
        </html>
  '
  def test_to_plain
    cv = Sisimai::String.to_plain(Ht1)
    assert_instance_of String, cv
    refute_empty cv
    assert_equal true, cv.size < Ht1.size

    refute_match /<html>/, cv
    refute_match /<head>/, cv
    refute_match /<body>/, cv
    refute_match /<div>/,  cv

    assert_match %r/\bneko\b/,        Sisimai::String.to_plain('neko')
    assert_match %r/\[Sisimai\]/,     Sisimai::String.to_plain('[Sisimai]')
    assert_match %r|[(]http://.+[)]|, Sisimai::String.to_plain('(http://...)')
    assert_match %r/[(]mailto:.+[)]/, Sisimai::String.to_plain('(mailto:...)')

    cv = Sisimai::String.to_plain('<body>Nyaan</body>', true)
    refute_empty cv
    refute_match /<body>/, cv
    assert_match /Nyaan/,  cv

    cv = Sisimai::String.to_plain('<body>Nyaan</body>', false)
    refute_empty cv
    assert_match /<body>/, cv
    assert_match /Nyaan/,  cv

    ce = assert_raises ArgumentError do
      Sisimai::String.to_plain()
      Sisimai::String.to_plain("", false, nil)
    end
    assert_match /wrong number of arguments/, ce.to_s
  end



end
