module LhostEngineTest::Public
  module Exchange2003
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.213', '',    'userunknown',      true,  true]],
      '02' => [['5.9.213', '',    'userunknown',      true,  true],
               ['5.9.213', '',    'userunknown',      true,  true]],
      '03' => [['5.9.213', '',    'userunknown',      true,  true]],
      '04' => [['5.9.210', '',    'filtered',        false, false]],
      '05' => [['5.9.213', '',    'userunknown',      true,  true]],
      '07' => [['5.9.213', '',    'userunknown',      true,  true]],
    }
  end
end

