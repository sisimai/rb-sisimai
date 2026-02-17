module LhostEngineTest::Private
  module Exchange2007
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1002'  => [['5.2.3',   '550', 'emailtoolarge',   false, false]],
      '1003'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1004'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1005'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1006'  => [['5.2.3',   '550', 'emailtoolarge',   false, false]],
      '1007'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1008'  => [['5.7.1',   '550', 'securityerror',   false, false]],
      '1009'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1010'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1011'  => [['5.2.3',   '550', 'emailtoolarge',   false, false]],
      '1012'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1013'  => [['5.9.210', '550', 'filtered',        false,  true]],
      '1014'  => [['4.2.0',   '',    'systemerror',     false, false]],
      '1015'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1016'  => [['5.2.3',   '550', 'emailtoolarge',   false, false]],
      '1017'  => [['5.1.10',  '550', 'userunknown',      true,  true]],
      '1018'  => [['5.1.10',  '550', 'userunknown',      true,  true]],
      '1019'  => [['5.4.317', '550', 'failedstarttls',  false, false]],
      '1020'  => [['5.7.23',  '550', 'authfailure',     false, false]],
      '1021'  => [['5.7.509', '550', 'authfailure',     false, false]],
      '1022'  => [['5.4.317', '550', 'failedstarttls',  false, false]],
      '1023'  => [['5.4.317', '550', 'failedstarttls',  false, false]],
      '1024'  => [['5.4.318', '550', 'systemerror',     false, false]],
      '1025'  => [['5.1.351', '550', 'userunknown',      true,  true]],
      '1026'  => [['4.2.0',   '',    'systemerror',     false, false]],
      '1027'  => [['5.4.3',   '550', 'systemerror',     false, false]], # TODO: 5.4.3
      '1028'  => [['5.7.520', '550', 'securityerror',   false, false]],
      '1029'  => [['5.7.1',   '550', 'policyviolation', false, false]],
      '1030'  => [['5.4.317', '550', 'expired',         false, false]],
      '1031'  => [['5.1.351', '550', 'filtered',        false,  true]],
      '1032'  => [['5.0.350', '550', 'norelaying',      false,  true]],
      '1033'  => [['5.0.350', '550', 'norelaying',      false,  true]],
      '1034'  => [['5.7.193', '550', 'rejected',        false, false]],
    }
  end
end

