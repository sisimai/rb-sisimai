module LhostEngineTest::Private
  module AmazonSES
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1002'  => [['5.2.1',   '550', 'filtered',        false, 1]],
      '1003'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1004'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1005'  => [['5.7.1',   '550', 'securityerror',   false, 0]],
      '1006'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1007'  => [['5.4.7',   '',    'expired',         false, 0]],
      '1008'  => [['5.1.2',   '',    'hostunknown',      true, 1]],
      '1009'  => [['5.1.0',   '550', 'userunknown',      true, 1]],
      '1010'  => [['5.1.0',   '550', 'userunknown',      true, 1]],
      '1011'  => [['5.1.0',   '550', 'userunknown',      true, 1]],
      '1012'  => [['5.1.0',   '550', 'userunknown',      true, 1]],
      '1013'  => [['5.1.0',   '550', 'userunknown',      true, 1]],
      '1014'  => [['5.3.0',   '550', 'filtered',        false, 1]],
      '1015'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1016'  => [['',        '',    'feedback',        false, 1, 'abuse']],
      '1017'  => [['2.6.0',   '250', 'delivered',       false, 0]],
      '1018'  => [['2.6.0',   '250', 'delivered',       false, 0]],
      '1019'  => [['5.7.1',   '554', 'blocked',         false, 0]],
      '1020'  => [['4.4.2',   '421', 'expired',         false, 0]],
      '1021'  => [['5.4.4',   '550', 'hostunknown',      true, 1]],
      '1022'  => [['5.5.1',   '550', 'blocked',         false, 0]],
      '1023'  => [['5.7.1',   '550', 'suspend',         false, 1]],
      '1024'  => [['5.4.1',   '550', 'userunknown',      true, 1]],
      '1025'  => [['5.2.1',   '550', 'suspend',         false, 1]],
      '1026'  => [['5.7.1',   '554', 'norelaying',      false, 1]],
      '1027'  => [['5.2.2',   '552', 'mailboxfull',     false, 1]],
      '1028'  => [['5.4.7',   '',    'expired',         false, 0]],
      '1029'  => [['5.1.0',   '550', 'userunknown',      true, 1]],
      '1030'  => [['2.6.0',   '250', 'delivered',       false, 0]],
      '1031'  => [['2.6.0',   '250', 'delivered',       false, 0]],
    }
  end
end

