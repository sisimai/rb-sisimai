module LhostEngineTest::Public
  module Yandex
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.2.1',   '550', 'userunknown',      true, 1],
               ['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '03' => [['4.4.1',   '',    'expired',         false, 0]],
    }
  end
end

