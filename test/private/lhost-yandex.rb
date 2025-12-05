module LhostEngineTest::Private
  module Yandex
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1002'  => [['5.2.1',   '550', 'userunknown',      true,  true],
                  ['5.2.2',   '550', 'mailboxfull',     false,  true]],
    }
  end
end

