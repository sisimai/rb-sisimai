module RhostEngineTest::Public
  module YahooInc
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.7.9',   '554', 'policyviolation', false, false]],
      '02' => [['4.7.0',   '421', 'rejected',        false, false]],
      '03' => [['5.0.0',   '554', 'userunknown',      true,  true]],
    }
  end
end

