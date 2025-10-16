module LhostEngineTest::Private
  module X1
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '1001'  => [['5.0.910', '',    'filtered',        false]],
      '1002'  => [['5.0.910', '',    'filtered',        false],
                  ['5.0.910', '',    'filtered',        false]],
      '1003'  => [['5.0.910', '',    'filtered',        false]],
      '1004'  => [['5.0.910', '',    'filtered',        false]],
      '1005'  => [['5.0.910', '',    'filtered',        false]],
      '1006'  => [['5.0.910', '',    'filtered',        false]],
      '1007'  => [['5.0.947', '',    'expired',         false]],
    }
  end
end

