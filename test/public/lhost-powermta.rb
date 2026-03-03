module LhostEngineTest::Public
  module PowerMTA
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.2.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.0.0',   '554', 'userunknown',      true, 1]],
      '03' => [['5.2.1',   '550', 'userunknown',      true, 1]],
    }
  end
end

