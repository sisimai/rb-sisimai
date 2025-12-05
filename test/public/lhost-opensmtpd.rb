module LhostEngineTest::Public
  module OpenSMTPD
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false,  true],
               ['5.1.1',   '550', 'userunknown',      true,  true]],
      '03' => [['5.0.912', '',    'hostunknown',      true,  true]],
      '04' => [['5.0.944', '',    'networkerror',    false, false]],
      '05' => [['5.0.947', '',    'expired',         false, false]],
      '06' => [['5.0.947', '',    'expired',         false, false]],
      '10' => [['5.0.912', '',    'hostunknown',      true,  true]],
      '11' => [['5.7.26',  '550', 'authfailure',     false, false]],
      '12' => [['5.0.932', '',    'notaccept',        true,  true]],
      '13' => [['4.7.0',   '421', 'badreputation',   false, false]],
      '14' => [['5.7.25',  '550', 'requireptr',      false, false]],
      '15' => [['5.0.947', '',    'expired',         false, false]],
      '16' => [['5.0.947', '',    'expired',         false, false]],
      '17' => [['5.1.1',   '550', 'userunknown',      true,  true],
               ['5.2.2',   '552', 'mailboxfull',     false,  true]],
    }
  end
end

