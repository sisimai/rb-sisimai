module LhostEngineTest::Private
  module McAfee
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.0.911', '550', 'userunknown',     true,  true]],
      '1002'  => [['5.0.910', '550', 'filtered',       false,  true]],
      '1003'  => [['5.1.1',   '550', 'userunknown',     true,  true]],
      '1004'  => [['5.1.1',   '550', 'userunknown',     true,  true]],
      '1005'  => [['5.1.1',   '550', 'userunknown',     true,  true]],
      '1006'  => [['5.1.1',   '550', 'userunknown',     true,  true]],
      '1007'  => [['5.0.911', '550', 'userunknown',     true,  true]],
      '1008'  => [['5.0.910', '550', 'filtered',       false,  true]],
      '1009'  => [['5.0.910', '550', 'filtered',       false,  true]],
    }
  end
end

