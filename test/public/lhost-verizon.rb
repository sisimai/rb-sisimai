module LhostEngineTest::Public
  module Verizon
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.213', '',    'userunknown',      true,  true]],
      '02' => [['5.9.213', '550', 'userunknown',      true,  true]],
    }
  end
end

