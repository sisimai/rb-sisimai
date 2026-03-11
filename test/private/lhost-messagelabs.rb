module LhostEngineTest::Private
  module MessageLabs
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1002'  => [['5.0.0',   '550', 'securityerror',   false, 0]],
      '1003'  => [['5.0.0',   '',    'userunknown',      true, 1]],
      '1004'  => [['5.0.0',   '550', 'userunknown',      true, 1]],
    }
  end
end

