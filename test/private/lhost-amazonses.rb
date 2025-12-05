module LhostEngineTest::Private
  module AmazonSES
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1002'  => [['5.2.1',   '550', 'filtered',        false,  true]],
      '1003'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1004'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1005'  => [['5.7.1',   '550', 'securityerror',   false, false]],
      '1006'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1007'  => [['5.4.7',   '',    'expired',         false, false]],
      '1008'  => [['5.1.2',   '',    'hostunknown',      true,  true]],
      '1009'  => [['5.1.0',   '550', 'userunknown',      true,  true]],
      '1010'  => [['5.1.0',   '550', 'userunknown',      true,  true]],
      '1011'  => [['5.1.0',   '550', 'userunknown',      true,  true]],
      '1012'  => [['5.1.0',   '550', 'userunknown',      true,  true]],
      '1013'  => [['5.1.0',   '550', 'userunknown',      true,  true]],
      '1014'  => [['5.3.0',   '550', 'filtered',        false,  true]],
      '1015'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1016'  => [['',        '',    'feedback',        false,  true, 'abuse']],
      '1017'  => [['2.6.0',   '250', 'delivered',       false, false]],
      '1018'  => [['2.6.0',   '250', 'delivered',       false, false]],
      '1019'  => [['5.7.1',   '554', 'blocked',         false, false]],
      '1020'  => [['4.4.2',   '421', 'expired',         false, false]],
      '1021'  => [['5.4.4',   '550', 'hostunknown',      true,  true]],
      '1022'  => [['5.5.1',   '550', 'blocked',         false, false]],
      '1023'  => [['5.7.1',   '550', 'suspend',         false,  true]],
      '1024'  => [['5.4.1',   '550', 'userunknown',      true,  true]],
      '1025'  => [['5.2.1',   '550', 'suspend',         false,  true]],
      '1026'  => [['5.7.1',   '554', 'norelaying',      false,  true]],
      '1027'  => [['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '1028'  => [['5.4.7',   '',    'expired',         false, false]],
      '1029'  => [['5.1.0',   '550', 'userunknown',      true,  true]],
      '1030'  => [['2.6.0',   '250', 'delivered',       false, false]],
      '1031'  => [['2.6.0',   '250', 'delivered',       false, false]],
    }
  end
end

