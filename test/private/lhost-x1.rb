module LhostEngineTest::Private
  module X1
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.0.910', '',    'filtered',        false, false]],
      '1002'  => [['5.0.910', '',    'filtered',        false, false],
                  ['5.0.910', '',    'filtered',        false, false]],
      '1003'  => [['5.0.910', '',    'filtered',        false, false]],
      '1004'  => [['5.0.910', '',    'filtered',        false, false]],
      '1005'  => [['5.0.910', '',    'filtered',        false, false]],
      '1006'  => [['5.0.910', '',    'filtered',        false, false]],
      '1007'  => [['5.0.947', '',    'expired',         false, false]],
      '1008'  => [['5.0.921', '',    'suspend',         false,  true]],
    }
  end
end

