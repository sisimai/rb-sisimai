module LhostEngineTest::Private
  module Yahoo
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1002'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1003'  => [['5.2.1',   '550', 'userunknown',      true, 1]],
      '1004'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1005'  => [['5.9.134', '554', 'blocked',         false, 0]],
      '1006'  => [['5.9.213', '550', 'userunknown',      true, 1]],
      '1007'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1008'  => [['5.9.215', '',    'notaccept',        true, 1]],
      '1009'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1010'  => [['5.1.8',   '501', 'rejected',        false, 0]],
      '1011'  => [['5.9.134', '554', 'blocked',         false, 0]],
    }
  end
end

