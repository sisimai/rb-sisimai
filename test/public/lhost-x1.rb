module LhostEngineTest::Public
  module X1
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.210', '',    'filtered',        false, 0]],
      '02' => [['5.9.210', '',    'filtered',        false, 0]],
      '03' => [['5.9.210', '',    'filtered',        false, 0]],
      '04' => [['5.9.340', '',    'expired',         false, 0]],
    }
  end
end

