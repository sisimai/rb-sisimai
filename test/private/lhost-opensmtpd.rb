module LhostEngineTest::Private
  module OpenSMTPD
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1002'  => [['5.2.1',   '550', 'filtered',        false, 1]],
      '1003'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1004'  => [['5.9.213', '550', 'userunknown',      true, 1]],
      '1005'  => [['5.9.213', '550', 'userunknown',      true, 1]],
      '1006'  => [['5.9.340', '',    'expired',         false, 0]],
      '1007'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1008'  => [['5.2.2',   '550', 'mailboxfull',     false, 1],
                  ['5.1.1',   '550', 'userunknown',      true, 1]],
      '1009'  => [['5.9.212', '',    'hostunknown',      true, 1]],
      '1010'  => [['5.9.341', '',    'networkerror',    false, 0]],
      '1011'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1012'  => [['5.2.2',   '550', 'mailboxfull',     false, 1],
                  ['5.1.1',   '550', 'userunknown',      true, 1]],
      '1013'  => [['5.9.212', '',    'hostunknown',      true, 1]],
      '1014'  => [['5.9.340', '',    'expired',         false, 0]],
      '1015'  => [['5.9.341', '',    'networkerror',    false, 0]],
      '1016'  => [['5.9.212', '',    'hostunknown',      true, 1]],
      '1017'  => [['5.7.26',  '550', 'authfailure',     false, 0]],
      '1018'  => [['5.9.215', '',    'notaccept',        true, 1]],
    }
  end
end

