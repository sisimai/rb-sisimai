module LhostEngineTest::Public
  module TrendMicro
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.0.911', '',    'userunknown',      true,  true]],
      '03' => [['5.0.911', '',    'userunknown',      true,  true]], 
    }
  end
end

