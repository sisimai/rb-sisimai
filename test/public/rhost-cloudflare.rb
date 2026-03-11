module RhostEngineTest::Public
  module Cloudflare
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['4.3.0',   '421', 'systemerror',     false, 0]],
    }
  end
end

