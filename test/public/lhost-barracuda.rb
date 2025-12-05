module LhostEngineTest::Public
  module Barracuda
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.7.1',   '550', 'spamdetected',    false, false]],
      '02' => [['5.7.1',   '550', 'spamdetected',    false, false]],
    }
  end
end

