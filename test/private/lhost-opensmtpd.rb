module LhostEngineTest::Private
  module OpenSMTPD
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1002'  => [['5.2.1',   '550', 'filtered',        false]],
      '1003'  => [['5.2.2',   '550', 'mailboxfull',     false]],
      '1004'  => [['5.0.911', '550', 'userunknown',      true]],
      '1005'  => [['5.0.911', '550', 'userunknown',      true]],
      '1006'  => [['5.0.947', '',    'expired',         false]],
      '1007'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1008'  => [['5.2.2',   '550', 'mailboxfull',     false],
                  ['5.1.1',   '550', 'userunknown',     true]],
      '1009'  => [['5.0.912', '',    'hostunknown',     true]],
      '1010'  => [['5.0.944', '',    'networkerror',    false]],
      '1011'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1012'  => [['5.2.2',   '550', 'mailboxfull',     false],
                  ['5.1.1',   '550', 'userunknown',     true]],
      '1013'  => [['5.0.912', '',    'hostunknown',     true]],
      '1014'  => [['5.0.947', '',    'expired',         false]],
      '1015'  => [['5.0.944', '',    'networkerror',    false]],
      '1016'  => [['5.0.912', '',    'hostunknown',     true]],
      '1017'  => [['5.7.26',  '550', 'authfailure',     false]],
      '1018'  => [['5.0.932', '',    'notaccept',       true]],
    }
  end
end

