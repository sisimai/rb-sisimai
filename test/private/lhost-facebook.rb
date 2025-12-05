module LhostEngineTest::Private
  module Facebook
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'filtered',         true,  true]],
      '1002'  => [['5.1.1',   '550', 'filtered',         true,  true]],
      '1003'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
    }
  end
end

