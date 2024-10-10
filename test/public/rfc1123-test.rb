require 'minitest/autorun'
require 'sisimai/rfc1123'

class RFC1123Test < Minitest::Test
  Methods = { class: %w[is_validhostname] }

  Hostnames0 = [
    '',
    'localhost',
    '127.0.0.1',
    'cat',
    'neko',
    'nyaan.22',
    'mx0.example.22',
    'mx0.example.jp-',
    'mx--0.example.jp',
    'mx..0.example.jp',
    'mx0.example.jp/neko',
  ]
  Hostnames1 = [
    'mx1.example.jp',
    'mx1.example.jp.',
    'a.jp',
  ]

  def test_is_validhostname
    Hostnames0.each do |e|
      # Invalid hostnames
      assert_equal false, Sisimai::RFC1123.is_validhostname(e)
    end

    Hostnames1.each do |e|
      # Valid hostnames
      assert_equal true,  Sisimai::RFC1123.is_validhostname(e)
    end

    ce = assert_raises ArgumentError do
      Sisimai::RFC1123.is_validhostname(nil, nil)
    end
  end

end

