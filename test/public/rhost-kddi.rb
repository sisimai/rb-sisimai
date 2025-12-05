module RhostEngineTest::Public
  module KDDI
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.2.0',   '550', 'filtered',        false,  true]],
      '02' => [['5.1.1',   '550', 'userunknown',      true,  true]],
    }
  end
end

