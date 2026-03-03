module LhostEngineTest::Private
  module SendGrid
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1002'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1003'  => [['5.9.340', '',    'expired',         false, 0]],
      '1004'  => [['5.9.213', '550', 'userunknown',      true, 1]],
      '1005'  => [['5.2.1',   '550', 'userunknown',      true, 1]],
      '1006'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1007'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1008'  => [['5.9.213', '554', 'userunknown',      true, 1]],
      '1009'  => [['5.9.213', '550', 'userunknown',      true, 1]],
    }
  end
end

