module LhostEngineTest::Private
  module Office365
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '1002'  => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '1003'  => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '1004'  => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '1005'  => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '1006'  => [['5.4.14',  '554', 'networkerror',    false, 0]],
      '1007'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1008'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1009'  => [['5.9.370', '553', 'securityerror',   false, 0]],
      '1010'  => [['5.1.0',   '550', 'authfailure',     false, 0]],
      '1011'  => [['5.1.351', '550', 'filtered',        false, 1]],
      '1012'  => [['5.1.8',   '501', 'rejected',        false, 0]],
      '1013'  => [['5.4.312', '550', 'networkerror',    false, 0]],
      '1014'  => [['5.1.351', '550', 'filtered',        false, 1]],
      '1015'  => [['5.1.351', '550', 'filtered',        false, 1]],
      '1016'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1017'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1018'  => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '1019'  => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '1020'  => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '1021'  => [['5.4.14',  '554', 'networkerror',    false, 0]],
      '1022'  => [['5.2.14',  '550', 'systemerror',     false, 0]],
      '1023'  => [['5.4.310', '550', 'norelaying',      false, 1]],
      '1024'  => [['5.4.310', '550', 'norelaying',      false, 1]],
#     '1025'  => [['5.1.10',  '550', 'userunknown',      true, 1]], # TODO:
    }
  end
end

