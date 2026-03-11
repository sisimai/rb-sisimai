module LhostEngineTest::Private
  module ApacheJames
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1002'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1003'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1004'  => [['5.9.301', '',    'onhold',          false, 0]],
      '1005'  => [['5.9.301', '',    'onhold',          false, 0]],
    }
  end
end

