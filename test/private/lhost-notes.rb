module LhostEngineTest::Private
  module Notes
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.213', '',    'userunknown',      true, 1]],
      '1002'  => [['5.9.301', '',    'onhold',          false, 0]],
      '1003'  => [['5.9.301', '',    'onhold',          false, 0]],
      '1004'  => [['5.9.213', '',    'userunknown',      true, 1]],
      '1005'  => [['5.9.301', '',    'onhold',          false, 0]],
      '1006'  => [['5.9.213', '',    'userunknown',      true, 1]],
      '1007'  => [['5.9.213', '',    'userunknown',      true, 1]],
      '1008'  => [['5.9.213', '',    'userunknown',      true, 1]],
      '1009'  => [['5.9.213', '',    'userunknown',      true, 1]],
      '1010'  => [['5.9.341', '',    'networkerror',    false, 0]],
    }
  end
end

