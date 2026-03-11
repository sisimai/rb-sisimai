module LhostEngineTest::Private
  module X4
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1002'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1003'  => [['5.1.2',   '',    'hostunknown',      true, 1]],
      '1004'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1005'  => [['5.9.213', '550', 'userunknown',      true, 1]],
      '1006'  => [['5.1.1',   '',    'userunknown',      true, 1]],
      '1007'  => [['5.9.213', '550', 'userunknown',      true, 1]],
      '1008'  => [['5.9.221', '550', 'suspend',         false, 1]],
      '1009'  => [['5.1.1',   '',    'userunknown',      true, 1]],
      '1010'  => [['5.1.2',   '',    'hostunknown',      true, 1]],
      '1011'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1012'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1013'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1014'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1015'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1016'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1018'  => [['5.1.1',   '',    'userunknown',      true, 1]],
      '1019'  => [['5.9.213', '550', 'userunknown',      true, 1]],
      '1020'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1022'  => [['5.1.1',   '',    'userunknown',      true, 1]],
      '1023'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1024'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1025'  => [['5.1.1',   '',    'userunknown',      true, 1]],
      '1026'  => [['5.9.213', '550', 'userunknown',      true, 1]],
      '1027'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
    }
  end
end

