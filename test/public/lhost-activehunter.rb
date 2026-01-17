module LhostEngineTest::Public
  module Activehunter
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.9.210', '550', 'filtered',        false,  true]],
    }
  end
end

