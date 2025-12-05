module LhostEngineTest::Public
  module McAfee
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.910', '550', 'filtered',       false,  true]],
      '02' => [['5.1.1',   '550', 'userunknown',     true,  true]],
      '03' => [['5.1.1',   '550', 'userunknown',     true,  true]],
      '04' => [['5.0.910', '550', 'filtered',       false,  true]],
      '05' => [['5.0.910', '550', 'filtered',       false,  true]],
    }
  end
end

