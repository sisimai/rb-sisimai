module RhostEngineTest::Public
  module YahooInc
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.7.9',   '554', 'policyviolation', false]],
      '02' => [['4.7.0',   '421', 'badreputation',   false]],
      '03' => [['5.0.0',   '554', 'userunknown',     true]],
    }
  end
end

