module LhostEngineTest::Private
  module Exchange2007
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1002'  => [['5.2.3',   '550', 'emailtoolarge',   false, 0]],
      '1003'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1004'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1005'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1006'  => [['5.2.3',   '550', 'emailtoolarge',   false, 0]],
      '1007'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1008'  => [['5.7.1',   '550', 'securityerror',   false, 0]],
      '1009'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1010'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1011'  => [['5.2.3',   '550', 'emailtoolarge',   false, 0]],
      '1012'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1013'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1014'  => [['4.2.0',   '',    'systemerror',     false, 0]],
      '1015'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1016'  => [['5.2.3',   '550', 'emailtoolarge',   false, 0]],
      '1017'  => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '1018'  => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '1019'  => [['5.4.317', '550', 'failedstarttls',  false, 0]],
      '1020'  => [['5.7.23',  '550', 'authfailure',     false, 0]],
      '1021'  => [['5.7.509', '550', 'authfailure',     false, 0]],
      '1022'  => [['5.4.317', '550', 'failedstarttls',  false, 0]],
      '1023'  => [['5.4.317', '550', 'failedstarttls',  false, 0]],
      '1024'  => [['5.4.318', '550', 'systemerror',     false, 0]],
      '1025'  => [['5.1.351', '550', 'userunknown',      true, 1]],
      '1026'  => [['4.2.0',   '',    'systemerror',     false, 0]],
      '1027'  => [['5.4.3',   '550', 'systemerror',     false, 0]], # TODO: 5.4.3
      '1028'  => [['5.7.520', '550', 'securityerror',   false, 0]],
      '1029'  => [['5.7.1',   '550', 'policyviolation', false, 0]],
      '1030'  => [['5.4.317', '550', 'expired',         false, 0]],
      '1031'  => [['5.1.351', '550', 'filtered',        false, 1]],
      '1032'  => [['5.0.350', '550', 'norelaying',      false, 1]],
      '1033'  => [['5.0.350', '550', 'norelaying',      false, 1]],
      '1034'  => [['5.7.193', '550', 'rejected',        false, 0]],
    }
  end
end

