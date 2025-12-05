module LhostEngineTest::Public
  module EZweb
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.910', '',    'filtered',        false,  true]],
      '02' => [['5.0.0',   '550', 'suspend',         false,  true]],
      '03' => [['5.0.921', '',    'suspend',         false,  true]],
      '04' => [['5.0.911', '550', 'userunknown',      true,  true]],
      '05' => [['5.0.947', '',    'expired',         false, false]],
      '07' => [['5.0.911', '550', 'userunknown',      true,  true]],
      '08' => [['5.0.971', '550', 'blocked',         false, false]],
    }
  end
end

