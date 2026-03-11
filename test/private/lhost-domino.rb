module LhostEngineTest::Private
  module Domino
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001' => [['5.0.0',   '',    'onhold',          false, 0]],
      '1002' => [['5.1.1',   '',    'userunknown',      true, 1]],
      '1003' => [['5.0.0',   '',    'userunknown',      true, 1]],
      '1004' => [['5.0.0',   '',    'userunknown',      true, 1]],
      '1005' => [['5.0.0',   '',    'onhold',          false, 0]],
      '1006' => [['5.9.213', '',    'userunknown',      true, 1]],
      '1007' => [['5.0.0',   '',    'userunknown',      true, 1]],
      '1008' => [['5.9.213', '',    'userunknown',      true, 1]],
      '1009' => [['5.9.213', '',    'userunknown',      true, 1]],
      '1010' => [['5.9.213', '',    'userunknown',      true, 1]],
      '1011' => [['5.1.1',   '',    'userunknown',      true, 1]],
      '1012' => [['5.9.213', '',    'userunknown',      true, 1]],
      '1013' => [['5.9.213', '',    'userunknown',      true, 1]],
      '1014' => [['5.9.213', '',    'userunknown',      true, 1]],
      '1015' => [['5.0.0',   '',    'networkerror',    false, 0]],
      '1016' => [['5.0.0',   '',    'systemerror',     false, 0]],
      '1017' => [['5.0.0',   '',    'userunknown',      true, 1]],
      '1019' => [['5.0.0',   '',    'userunknown',      true, 1]],
    }
  end
end

