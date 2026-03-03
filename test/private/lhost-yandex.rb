module LhostEngineTest::Private
  module Yandex
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1002'  => [['5.2.1',   '550', 'userunknown',      true, 1],
                  ['5.2.2',   '550', 'mailboxfull',     false, 1]],
    }
  end
end

