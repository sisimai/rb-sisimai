require 'minitest/autorun'
require 'sisimai/rfc5965'

class RFC5965Test < Minitest::Test
  Methods = { class: %w[FIELDINDEX] }

  def test_methods
    Methods[:class].each { |e| assert_respond_to Sisimai::RFC5965, e }
  end

  def test_FIELDINDEX
    cv = Sisimai::RFC5965.FIELDINDEX
    assert_instance_of Array, cv
    refute_empty cv

    ce = assert_raises ArgumentError do
      Sisimai::RFC5965.FIELDINDEX(nil)
    end
  end

end

