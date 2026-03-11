module LhostEngineTest::Private
  module X1
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.210', '',    'filtered',        false, 0]],
      '1002'  => [['5.9.210', '',    'filtered',        false, 0],
                  ['5.9.210', '',    'filtered',        false, 0]],
      '1003'  => [['5.9.210', '',    'filtered',        false, 0]],
      '1004'  => [['5.9.210', '',    'filtered',        false, 0]],
      '1005'  => [['5.9.210', '',    'filtered',        false, 0]],
      '1006'  => [['5.9.210', '',    'filtered',        false, 0]],
      '1007'  => [['5.9.340', '',    'expired',         false, 0]],
      '1008'  => [['5.9.221', '',    'suspend',         false, 1]],
    }
  end
end

