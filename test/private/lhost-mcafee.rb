module LhostEngineTest::Private
  module McAfee
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '1001'  => [['5.0.911', '550', 'userunknown',     true]],
      '1002'  => [['5.0.910', '550', 'filtered',       false]],
      '1003'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1004'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1005'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1006'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1007'  => [['5.0.911', '550', 'userunknown',     true]],
      '1008'  => [['5.0.910', '550', 'filtered',       false]],
      '1009'  => [['5.0.910', '550', 'filtered',       false]],
    }
  end
end

