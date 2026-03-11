module LhostEngineTest::Public
  module Domino
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.213', '',    'userunknown',      true, 1]],
      '02' => [['5.0.0',   '',    'userunknown',      true, 1]],
      '03' => [['5.0.0',   '',    'networkerror',    false, 0]],
    }
  end
end

