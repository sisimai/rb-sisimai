module LhostEngineTest::Public
  module TrendMicro
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.9.213', '',    'userunknown',      true, 1]],
      '03' => [['5.9.213', '',    'userunknown',      true, 1]], 
    }
  end
end

