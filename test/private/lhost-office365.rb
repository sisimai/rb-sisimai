module LhostEngineTest::Private
  module Office365
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.10',  '550', 'userunknown',      true,  true]],
      '1002'  => [['5.1.10',  '550', 'userunknown',      true,  true]],
      '1003'  => [['5.1.10',  '550', 'userunknown',      true,  true]],
      '1004'  => [['5.1.10',  '550', 'userunknown',      true,  true]],
      '1005'  => [['5.1.10',  '550', 'userunknown',      true,  true]],
      '1006'  => [['5.4.14',  '554', 'networkerror',    false, false]],
      '1007'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1008'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1009'  => [['5.9.370', '553', 'securityerror',   false, false]],
      '1010'  => [['5.1.0',   '550', 'authfailure',     false, false]],
      '1011'  => [['5.1.351', '550', 'filtered',        false,  true]],
      '1012'  => [['5.1.8',   '501', 'rejected',        false, false]],
      '1013'  => [['5.4.312', '550', 'networkerror',    false, false]],
      '1014'  => [['5.1.351', '550', 'filtered',        false,  true]],
      '1015'  => [['5.1.351', '550', 'filtered',        false,  true]],
      '1016'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1017'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1018'  => [['5.1.10',  '550', 'userunknown',      true,  true]],
      '1019'  => [['5.1.10',  '550', 'userunknown',      true,  true]],
      '1020'  => [['5.1.10',  '550', 'userunknown',      true,  true]],
      '1021'  => [['5.4.14',  '554', 'networkerror',    false, false]],
      '1022'  => [['5.2.14',  '550', 'systemerror',     false, false]],
      '1023'  => [['5.4.310', '550', 'norelaying',      false,  true]],
      '1024'  => [['5.4.310', '550', 'norelaying',      false,  true]],
#     '1025'  => [['5.1.10',  '550', 'userunknown',      true,  true]], # TODO:
    }
  end
end

