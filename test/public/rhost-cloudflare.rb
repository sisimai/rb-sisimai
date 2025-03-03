module RhostEngineTest::Public
  module Cloudflare
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['4.3.0',   '421', 'systemerror',     false]],
    }
  end
end

