module LhostEngineTest::Private
  module Zoho
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1002'  => [['5.2.1',   '550', 'filtered',        false,  true],
                  ['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1003'  => [['5.9.210', '550', 'filtered',        false,  true]],
      '1004'  => [['4.9.340', '421', 'expired',         false, false]],
    }
  end
end

