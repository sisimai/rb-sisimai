module RhostEngineTest::Public
  module YahooInc
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.7.9',   '554', 'policyviolation', false, 0]],
      '02' => [['4.7.0',   '421', 'rejected',        false, 0]],
      '03' => [['5.0.0',   '554', 'userunknown',      true, 1]],
    }
  end
end

