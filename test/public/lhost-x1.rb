module LhostEngineTest::Public
  module X1
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.910', '',    'filtered',        false, false]],
      '02' => [['5.0.910', '',    'filtered',        false, false]],
      '03' => [['5.0.910', '',    'filtered',        false, false]],
      '04' => [['5.0.947', '',    'expired',         false, false]],
    }
  end
end

