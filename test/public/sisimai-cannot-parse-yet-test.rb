require 'minitest/autorun'
require 'sisimai'

class EmailCouldNotBeParsedTest < Minitest::Test
  Samples = './set-of-emails/to-be-debugged-because/sisimai-cannot-parse-yet'

  def test_rise
    if Dir.exist?(Samples)
      assert_nil Sisimai.rise(Samples)
    end
  end
end

