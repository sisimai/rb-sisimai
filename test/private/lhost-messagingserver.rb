module LhostEngineTest::Private
  module MessagingServer
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.4.4',   '',    'hostunknown',      true,  true]],
      '1002'  => [['5.0.0',   '',    'mailboxfull',     false,  true]],
      '1003'  => [['5.7.1',   '550', 'filtered',        false,  true],
                  ['5.7.1',   '550', 'filtered',        false,  true]],
      '1004'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1005'  => [['5.4.4',   '',    'hostunknown',      true,  true]],
      '1006'  => [['5.7.1',   '550', 'filtered',        false,  true]],
      '1007'  => [['5.2.0',   '',    'mailboxfull',     false,  true]],
      '1008'  => [['5.2.1',   '550', 'filtered',        false,  true]],
      '1009'  => [['5.0.0',   '',    'mailboxfull',     false,  true]],
      '1010'  => [['5.2.0',   '',    'mailboxfull',     false,  true]],
      '1011'  => [['4.4.7',   '',    'expired',         false, false]],
      '1012'  => [['5.0.0',   '550', 'filtered',        false,  true]],
      '1013'  => [['4.2.2',   '',    'mailboxfull',     false, false]],
      '1014'  => [['4.2.2',   '',    'mailboxfull',     false, false]],
      '1015'  => [['5.0.0',   '550', 'filtered',        false,  true]],
      '1016'  => [['5.0.0',   '550', 'userunknown',      true,  true]],
      '1017'  => [['5.1.10',  '',    'notaccept',        true,  true]],
      '1018'  => [['5.1.8',   '501', 'rejected',        false, false]],
      '1019'  => [['4.2.2',   '',    'mailboxfull',     false, false]],
    }
  end
end

