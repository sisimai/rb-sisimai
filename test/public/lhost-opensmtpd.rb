module LhostEngineTest::Public
  module OpenSMTPD
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false, 1],
               ['5.1.1',   '550', 'userunknown',      true, 1]],
      '03' => [['5.9.212', '',    'hostunknown',      true, 1]],
      '04' => [['5.9.341', '',    'networkerror',    false, 0]],
      '05' => [['5.9.340', '',    'expired',         false, 0]],
      '06' => [['5.9.340', '',    'expired',         false, 0]],
      '10' => [['5.9.212', '',    'hostunknown',      true, 1]],
      '11' => [['5.7.26',  '550', 'authfailure',     false, 0]],
      '12' => [['5.9.215', '',    'notaccept',        true, 1]],
      '13' => [['4.7.0',   '421', 'badreputation',   false, 0]],
      '14' => [['5.7.25',  '550', 'requireptr',      false, 0]],
      '15' => [['5.9.340', '',    'expired',         false, 0]],
      '16' => [['5.9.340', '',    'expired',         false, 0]],
      '17' => [['5.1.1',   '550', 'userunknown',      true, 1],
               ['5.2.2',   '552', 'mailboxfull',     false, 1]],
    }
  end
end

