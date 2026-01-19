module LhostEngineTest::Private
  module Notes
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.213', '',    'userunknown',      true,  true]],
      '1002'  => [['5.9.301', '',    'onhold',          false, false]],
      '1003'  => [['5.9.301', '',    'onhold',          false, false]],
      '1004'  => [['5.9.213', '',    'userunknown',      true,  true]],
      '1005'  => [['5.9.301', '',    'onhold',          false, false]],
      '1006'  => [['5.9.213', '',    'userunknown',      true,  true]],
      '1007'  => [['5.9.213', '',    'userunknown',      true,  true]],
      '1008'  => [['5.9.213', '',    'userunknown',      true,  true]],
      '1009'  => [['5.9.213', '',    'userunknown',      true,  true]],
      '1010'  => [['5.9.341', '',    'networkerror',    false, false]],
    }
  end
end

