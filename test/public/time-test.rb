require 'minitest/autorun'
require 'sisimai/time'

class TimeTest < Minitest::Test
  Methods = { class: %w[new], object: %w[to_json] }

  def test_methods
    Methods[:class].each  { |e| assert_respond_to Sisimai::Time, e }
    Methods[:object].each { |e| assert_respond_to Sisimai::Time.new, e }
  end

  def test_new
    assert_instance_of Sisimai::Time, Sisimai::Time.new
    assert_instance_of Sisimai::Time, Sisimai::Time.new(22)

    ce = assert_raises TypeError do
      Sisimai::Time.new(nil, nil)
    end
    assert_match /no implicit conversion from nil to integer/, ce.to_s

    ce = assert_raises NoMethodError do
      Sisimai::Time.new(nil)
      Sisimai::Time.new(nil, nil)
    end
    assert_match /undefined method/, ce.to_s
  end

  def test_to_json
    cv = Sisimai::Time.new
    assert_instance_of Integer, cv.to_json
  end
end
