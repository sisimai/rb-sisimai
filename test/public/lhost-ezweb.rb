module LhostEngineTest::Public
  module EZweb
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.210', '',    'filtered',        false,  true]],
      '02' => [['5.0.0',   '550', 'suspend',         false,  true]],
      '03' => [['5.9.221', '',    'suspend',         false,  true]],
      '04' => [['5.9.213', '550', 'userunknown',      true,  true]],
      '05' => [['5.9.340', '',    'expired',         false, false]],
      '07' => [['5.9.213', '550', 'userunknown',      true,  true]],
      '08' => [['5.9.134', '550', 'blocked',         false, false]],
    }
  end
end

