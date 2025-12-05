module LhostEngineTest::Public
  module Verizon
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.911', '',    'userunknown',      true,  true]],
      '02' => [['5.0.911', '550', 'userunknown',      true,  true]],
    }
  end
end

