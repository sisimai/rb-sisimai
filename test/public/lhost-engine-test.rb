require 'minitest/autorun'
require 'sisimai/lhost'
require './test/public/lhost-code'

module LhostEngineTest
  class Children < Minitest::Test
    Lo = LhostCode.new("PUBLIC-LHOST-ENGINE-TEST")

    def test_lhostengine
      directory1 = './test/public'
      checksonly = ARGV[0] || ''
      emailindex = ARGV[1] || 0
      lhostindex = Sisimai::Lhost.index
      enginelist = []
      enginename = ''

      checksonly = '' if lhostindex.select { |v| v.downcase == checksonly.downcase }.empty?

      Dir.glob(directory1 + '/lhost-*.rb').each do |f|
        next if f.end_with?('-test.rb')
        next if f.end_with?('-code.rb')

        if checksonly.size > 0
          enginelist << checksonly
          break
        else
          enginelist << f.split('-')[1].sub(/[.]rb\z/, '')
        end
      end

      enginelist.each do |e|
        require sprintf("%s/lhost-%s.rb", directory1, e)
        enginename = lhostindex.select { |v| v.downcase == e }.shift
        lhostclass = Module.const_get('LhostEngineTest::Public::' << enginename)
        Lo.enginetest(enginename, lhostclass::IsExpected, false, emailindex)
      end

      printf("\n%d public engines, %d assertions, %d failures\n", enginelist.size, Lo.assertions, Lo.failures.size)
    end
  end
end

