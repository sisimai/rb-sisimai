module LhostEngineTest::Private
  module Yahoo
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1002'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1003'  => [['5.2.1',   '550', 'userunknown',      true,  true]],
      '1004'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1005'  => [['5.9.134', '554', 'blocked',         false, false]],
      '1006'  => [['5.9.213', '550', 'userunknown',      true,  true]],
      '1007'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1008'  => [['5.9.215', '',    'notaccept',        true,  true]],
      '1009'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1010'  => [['5.1.8',   '501', 'rejected',        false, false]],
      '1011'  => [['5.9.134', '554', 'blocked',         false, false]],
    }
  end
end

