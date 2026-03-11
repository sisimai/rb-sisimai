module LhostEngineTest::Public
  module Qmail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.5.0',   '550', 'userunknown',      true, 1]],
      '02' => [['5.1.1',   '550', 'userunknown',      true, 1],
               ['5.2.1',   '550', 'userunknown',      true, 1]],
      '03' => [['5.7.1',   '550', 'rejected',        false, 0]],
      '04' => [['5.0.0',   '501', 'blocked',         false, 0]],
      '05' => [['4.4.3',   '',    'systemerror',     false, 0]],
      '06' => [['4.2.2',   '450', 'mailboxfull',     false, 0]],
      '07' => [['4.4.1',   '',    'networkerror',    false, 0]],
      '08' => [['5.9.220', '552', 'mailboxfull',     false, 1]],
      '09' => [['5.7.606', '550', 'blocked',         false, 0]],
      '10' => [['5.9.221', '',    'suspend',         false, 1]],
      '11' => [['5.4.4',   '',    'notaccept',        true, 1]],
      '12' => [['5.4.4',   '',    'notaccept',        true, 1]],
      '13' => [['5.1.2',   '',    'hostunknown',      true, 1]],
      '14' => [['5.7.26',  '550', 'authfailure',     false, 0]],
      '15' => [['5.7.509', '550', 'authfailure',     false, 0]],
      '16' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '17' => [['5.1.1',   '550', 'userunknown',      true, 1],
               ['5.2.2',   '552', 'mailboxfull',     false, 1]],
      '18' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '19' => [['4.7.0',   '421', 'badreputation',   false, 0]],
      '20' => [['5.7.26',  '550', 'authfailure',     false, 0]],
      '21' => [['5.1.1',   '',    'userunknown',      true, 1]],
      '22' => [['5.7.509', '550', 'authfailure',     false, 0]],
      '23' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '24' => [['5.2.2',   '552', 'mailboxfull',     false, 1]],
      '25' => [['5.2.2',   '552', 'mailboxfull',     false, 1],
               ['5.1.1',   '550', 'userunknown',      true, 1]],
    }
  end
end

