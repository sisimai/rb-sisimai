module RhostEngineTest::Public
  module Facebook
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '03' => [['5.1.1',   '550', 'filtered',       false, 1]],
      '04' => [['5.1.1',   '550', 'userunknown',     true, 1]],
    }
  end
end

