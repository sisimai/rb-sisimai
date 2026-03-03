module LhostEngineTest::Public
  module X6
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.4.6',   '554', 'networkerror',    false, 0]],
      '02' => [['5.1.1',   '550', 'userunknown',      true, 1]],
    }
  end
end

