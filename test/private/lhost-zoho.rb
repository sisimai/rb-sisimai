module LhostEngineTest::Private
  module Zoho
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1002'  => [['5.2.1',   '550', 'filtered',        false, 1],
                  ['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1003'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1004'  => [['4.9.340', '421', 'expired',         false, 0]],
    }
  end
end

