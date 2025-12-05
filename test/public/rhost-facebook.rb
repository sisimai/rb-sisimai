module RhostEngineTest::Public
  module Facebook
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '03' => [['5.1.1',   '550', 'filtered',       false,  true]],
      '04' => [['5.1.1',   '550', 'userunknown',     true,  true]],
    }
  end
end

