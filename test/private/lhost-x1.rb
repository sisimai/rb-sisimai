module LhostEngineTest::Private
  module X1
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.210', '',    'filtered',        false, false]],
      '1002'  => [['5.9.210', '',    'filtered',        false, false],
                  ['5.9.210', '',    'filtered',        false, false]],
      '1003'  => [['5.9.210', '',    'filtered',        false, false]],
      '1004'  => [['5.9.210', '',    'filtered',        false, false]],
      '1005'  => [['5.9.210', '',    'filtered',        false, false]],
      '1006'  => [['5.9.210', '',    'filtered',        false, false]],
      '1007'  => [['5.9.340', '',    'expired',         false, false]],
      '1008'  => [['5.9.221', '',    'suspend',         false,  true]],
    }
  end
end

