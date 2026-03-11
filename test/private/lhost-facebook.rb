module LhostEngineTest::Private
  module Facebook
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'filtered',         true, 1]],
      '1002'  => [['5.1.1',   '550', 'filtered',         true, 1]],
      '1003'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
    }
  end
end

