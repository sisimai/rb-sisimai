require 'minitest/autorun'
require 'sisimai/rhost'
require 'sisimai'

class RhostTest < Minitest::Test
  Methods = { class:  %w[name find] }
  Classes = %w[
    Aol Apple Cloudflare Cox Facebook FrancePTT GoDaddy Google GSuite IUA KDDI MessageLabs Microsoft
    Mimecast NTTDOCOMO Outlook Spectrum Tencent YahooInc
  ]
  Objects = []

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::Rhost, e }
  end

  def test_name
    Dir.glob('./set-of-emails/maildir/bsd/rhost-*.eml').each do |e|
      cv = Sisimai.rise(e); assert_instance_of Array, cv
      warn "\nFile = " << e
      cv.each do |ee|
        assert_instance_of Sisimai::Fact, ee
        fo = ee.damn
        cx = Sisimai::Rhost.name(fo); refute_empty cx
        Objects << fo
      end
    end

    ce = assert_raises ArgumentError do
      Sisimai::Rhost.name()
      Sisimai::Rhost.name(nil, nil)
    end
  end

  def test_find
    Objects.each do |fo|
      cr = Sisimai::Rhost.find(fo); assert_instance_of ::String, cr

      ce = assert_raises ArgumentError do
        Sisimai::Rhost.find()
        Sisimai::Rhost.find(nil,  nil)
      end
    end
  end
end

