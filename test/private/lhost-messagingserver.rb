module LhostEngineTest::Private
  module MessagingServer
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.4.4',   '',    'hostunknown',      true, 1]],
      '1002'  => [['5.0.0',   '',    'mailboxfull',     false, 1]],
      '1003'  => [['5.7.1',   '550', 'filtered',        false, 1],
                  ['5.7.1',   '550', 'filtered',        false, 1]],
      '1004'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1005'  => [['5.4.4',   '',    'hostunknown',      true, 1]],
      '1006'  => [['5.7.1',   '550', 'filtered',        false, 1]],
      '1007'  => [['5.2.0',   '',    'mailboxfull',     false, 1]],
      '1008'  => [['5.2.1',   '550', 'filtered',        false, 1]],
      '1009'  => [['5.0.0',   '',    'mailboxfull',     false, 1]],
      '1010'  => [['5.2.0',   '',    'mailboxfull',     false, 1]],
      '1011'  => [['4.4.7',   '',    'expired',         false, 0]],
      '1012'  => [['5.0.0',   '550', 'filtered',        false, 1]],
      '1013'  => [['4.2.2',   '',    'mailboxfull',     false, 0]],
      '1014'  => [['4.2.2',   '',    'mailboxfull',     false, 0]],
      '1015'  => [['5.0.0',   '550', 'filtered',        false, 1]],
      '1016'  => [['5.0.0',   '550', 'userunknown',      true, 1]],
      '1017'  => [['5.1.10',  '',    'notaccept',        true, 1]],
      '1018'  => [['5.1.8',   '501', 'rejected',        false, 0]],
      '1019'  => [['4.2.2',   '',    'mailboxfull',     false, 0]],
    }
  end
end

