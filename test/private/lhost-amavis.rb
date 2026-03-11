module LhostEngineTest::Private
  module Amavis
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1002'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1003'  => [['5.7.0',   '554', 'notcompliantrfc', false, 0]],
    }
  end
end

