module LhostEngineTest::Private
  module Barracuda
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.7.1',   '550', 'spamdetected',    false, false]],
      '1002'  => [['5.7.1',   '550', 'spamdetected',    false, false]],
    }
  end
end

