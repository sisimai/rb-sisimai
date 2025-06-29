require 'minitest/autorun'
require 'sisimai/lhost'
require './test/public/lhost-code'

module LhostEngineTest
  class PrivateChildren < Minitest::Test
    Lx = LhostCode.new("PRIVATE-LHOST-ENGINE-TEST")

    def test_lhostengine
      directory1 = './test/private'
      patternset = ['lhost-*.rb', 'arf-*.rb', 'rfc3464.rb', 'rfc3834.rb'].map { |e| e = "#{directory1}/#{e}" }
      patternset.map { |e| e = directory1 + e }

      checksonly = ARGV[0] || ''
      emailindex = ARGV[1] || 0
      lhostindex = Sisimai::Lhost.index; lhostindex << 'ARF' << 'RFC3464' << 'RFC3834'
      otherlhost = %w[arf rfc3464 rfc3834]
      enginelist = []
      checksonly = '' if lhostindex.select { |v| v.downcase == checksonly.downcase }.empty?

      # Since v5.2.0, some Lhost modules have been removed
      alternates = {
        "Exchange2007" => %w[Office365],
        "Exim"         => %w[MailRu MXLogic],
        "Qmail"        => %w[X4 Yahoo],
        "RFC3464"      => %w[
            Aol Amavis AmazonWorkMail Barracuda Bigfoot Facebook GSuite McAfee MessageLabs Outlook
            PowerMTA ReceivingSES SendGrid SurfControl Yandex X5
        ],
      }

      Dir.glob(patternset).each do |f|
        next if f.end_with?('-test.rb')
        next if f.end_with?('-code.rb')

        if checksonly.size > 0
          enginelist << checksonly
          break
        else
          if f.include?('-')
            enginelist << f.split('-')[1].sub(/[.]rb\z/, '')
          else
            enginelist << f.split('/')[-1].sub(/[.]rb\z/, '')
          end
        end
      end

      enginelist.each do |e|
        # Find alternative Lhost engine name
        alterlhost = []
        enginename = ''
        alternates.each_key do |f|
          next unless alternates[f].any? { |a| e == a.downcase }
          enginename = f
          alterlhost << e
          break
        end
        if otherlhost.include?(e)
          require sprintf("%s/%s.rb", directory1, e)

        elsif alterlhost.include?(e)
          cv = enginename.downcase; cv = "lhost-" + cv if cv != "rfc3464"
          require sprintf("%s/%s.rb", directory1, cv)

        else
          require sprintf("%s/lhost-%s.rb", directory1, e)
        end

        enginename = lhostindex.select { |v| v.downcase == e }.shift if enginename.empty?
        lhostclass = Module.const_get("LhostEngineTest::Private::#{enginename}")
        Lx.enginetest(enginename, lhostclass::IsExpected, true, emailindex)
      end

      printf("\n%d private lhost engines, %d assertions, %d failures\n", enginelist.size, Lx.assertions, Lx.failures.size)
    end
  end
end

