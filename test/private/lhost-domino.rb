module LhostEngineTest::Private
  module Domino
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001' => [['5.0.0',   '',    'onhold',          false, false]],
      '1002' => [['5.1.1',   '',    'userunknown',      true,  true]],
      '1003' => [['5.0.0',   '',    'userunknown',      true,  true]],
      '1004' => [['5.0.0',   '',    'userunknown',      true,  true]],
      '1005' => [['5.0.0',   '',    'onhold',          false, false]],
      '1006' => [['5.9.213', '',    'userunknown',      true,  true]],
      '1007' => [['5.0.0',   '',    'userunknown',      true,  true]],
      '1008' => [['5.9.213', '',    'userunknown',      true,  true]],
      '1009' => [['5.9.213', '',    'userunknown',      true,  true]],
      '1010' => [['5.9.213', '',    'userunknown',      true,  true]],
      '1011' => [['5.1.1',   '',    'userunknown',      true,  true]],
      '1012' => [['5.9.213', '',    'userunknown',      true,  true]],
      '1013' => [['5.9.213', '',    'userunknown',      true,  true]],
      '1014' => [['5.9.213', '',    'userunknown',      true,  true]],
      '1015' => [['5.0.0',   '',    'networkerror',    false, false]],
      '1016' => [['5.0.0',   '',    'systemerror',     false, false]],
      '1017' => [['5.0.0',   '',    'userunknown',      true,  true]],
      '1019' => [['5.0.0',   '',    'userunknown',      true,  true]],
    }
  end
end

