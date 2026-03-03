module LhostEngineTest::Public
  module EZweb
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.210', '',    'filtered',        false, 1]],
      '02' => [['5.0.0',   '550', 'suspend',         false, 1]],
      '03' => [['5.9.221', '',    'suspend',         false, 1]],
      '04' => [['5.9.213', '550', 'userunknown',      true, 1]],
      '05' => [['5.9.340', '',    'expired',         false, 0]],
      '07' => [['5.9.213', '550', 'userunknown',      true, 1]],
      '08' => [['5.9.134', '550', 'blocked',         false, 0]],
    }
  end
end

