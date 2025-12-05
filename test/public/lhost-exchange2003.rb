module LhostEngineTest::Public
  module Exchange2003
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.911', '',    'userunknown',      true,  true]],
      '02' => [['5.0.911', '',    'userunknown',      true,  true],
               ['5.0.911', '',    'userunknown',      true,  true]],
      '03' => [['5.0.911', '',    'userunknown',      true,  true]],
      '04' => [['5.0.910', '',    'filtered',        false, false]],
      '05' => [['5.0.911', '',    'userunknown',      true,  true]],
      '07' => [['5.0.911', '',    'userunknown',      true,  true]],
    }
  end
end

