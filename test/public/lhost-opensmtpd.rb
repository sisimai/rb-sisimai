module LhostEngineTest::Public
  module OpenSMTPD
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',     true]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false],
               ['5.1.1',   '550', 'userunknown',     true]],
      '03' => [['5.0.912', '',    'hostunknown',     true]],
      '04' => [['5.0.944', '',    'networkerror',    false]],
      '05' => [['5.0.947', '',    'expired',         false]],
      '06' => [['5.0.947', '',    'expired',         false]],
      '10' => [['5.0.912', '',    'hostunknown',     true]],
      '11' => [['5.7.26',  '550', 'authfailure',     false]],
      '12' => [['5.0.932', '',    'notaccept',       true]],
      '13' => [['4.7.0',   '421', 'blocked',         false]],
      '14' => [['5.7.25',  '550', 'requireptr',      false]],
      '15' => [['5.0.947', '',    'expired',         false]],
      '16' => [['5.0.947', '',    'expired',         false]],
      '17' => [['5.1.1',   '550', 'userunknown',     true],
               ['5.2.2',   '552', 'mailboxfull',     false]],
    }
  end
end

