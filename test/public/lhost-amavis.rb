module LhostEngineTest::Public
  module Amavis
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '03' => [['5.7.0',   '554', 'notcompliantrfc', false, false]],
    }
  end
end

