module LhostEngineTest::Private
  module X3
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.3.0',   '553', 'userunknown',      true, 1]],
      '1002'  => [['5.9.300', '',    'undefined',       false, 0]],
      '1003'  => [['5.9.340', '',    'expired',         false, 0]],
      '1004'  => [['5.3.0',   '553', 'userunknown',      true, 1]],
      '1005'  => [['5.9.300', '',    'undefined',       false, 0]],
      '1006'  => [['5.3.0',   '553', 'userunknown',      true, 1]],
      '1007'  => [['5.9.340', '',    'expired',         false, 0]],
      '1008'  => [['5.3.0',   '553', 'userunknown',      true, 1]],
    }
  end
end

