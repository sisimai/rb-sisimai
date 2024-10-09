require 'minitest/autorun'
require 'sisimai/rhost'
require 'sisimai'

class RhostTest < Minitest::Test
  Methods = { class:  %w[find] }

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::Rhost, e }
  end

  def test_find
    Dir.glob('./set-of-emails/maildir/bsd/rhost-*.eml').each do |e|
      cv = Sisimai.rise(e)
      assert_instance_of Array, cv

      cv.each do |ee|
        assert_instance_of Sisimai::Fact, ee
        assert_instance_of String, ee.rhost
        assert_instance_of String, ee.reason
        refute_empty ee.rhost
        refute_empty ee.reason
        cx = ee.damn

        cr = Sisimai::Rhost.find(cx)
        refute_empty cx['destination']
        refute_empty cr
        assert_equal cx['reason'], cr
      end

    end

    ce = assert_raises ArgumentError do
      Sisimai::Rhost.find()
      Sisimai::Rhost.find(nil, nil, nil)
    end
  end
end

