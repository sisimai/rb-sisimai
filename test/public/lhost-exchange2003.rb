module LhostEngineTest::Public
  module Exchange2003
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.213', '',    'userunknown',      true, 1]],
      '02' => [['5.9.213', '',    'userunknown',      true, 1],
               ['5.9.213', '',    'userunknown',      true, 1]],
      '03' => [['5.9.213', '',    'userunknown',      true, 1]],
      '04' => [['5.9.210', '',    'filtered',        false, 0]],
      '05' => [['5.9.213', '',    'userunknown',      true, 1]],
      '07' => [['5.9.213', '',    'userunknown',      true, 1]],
    }
  end
end

