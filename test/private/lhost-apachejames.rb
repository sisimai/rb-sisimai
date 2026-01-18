module LhostEngineTest::Private
  module ApacheJames
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.210', '550', 'filtered',        false,  true]],
      '1002'  => [['5.9.210', '550', 'filtered',        false,  true]],
      '1003'  => [['5.9.210', '550', 'filtered',        false,  true]],
      '1004'  => [['5.9.301', '',    'onhold',          false, false]],
      '1005'  => [['5.9.301', '',    'onhold',          false, false]],
    }
  end
end

