require 'minitest/autorun'
require 'sisimai'
require 'sisimai/fact'
require 'json'

class ShouldNotCrashTest < Minitest::Test
  Samples = './set-of-emails/should-not-crash'

  def test_1
    f = Dir.open(Samples)
    while r = f.read do
      next if r == '.' || r == '..'
      assert_nil Sisimai.rise(Samples + "/" + r)
      assert_equal '[]', Sisimai.dump(Samples + "/" + r)
    end
  end
end

