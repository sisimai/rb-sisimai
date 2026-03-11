module LhostEngineTest::Private
  module Verizon
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.213', '',    'userunknown',      true, 1]],
      '1002'  => [['5.9.213', '550', 'userunknown',      true, 1]],
    }
  end
end

