module LhostEngineTest::Private
  module Verizon
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.0.911', '',    'userunknown',      true,  true]],
      '1002'  => [['5.0.911', '550', 'userunknown',      true,  true]],
    }
  end
end

