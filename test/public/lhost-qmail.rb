module LhostEngineTest::Public
  module Qmail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.5.0',   '550', 'userunknown',      true,  true]],
      '02' => [['5.1.1',   '550', 'userunknown',      true,  true],
               ['5.2.1',   '550', 'userunknown',      true,  true]],
      '03' => [['5.7.1',   '550', 'rejected',        false, false]],
      '04' => [['5.0.0',   '501', 'blocked',         false, false]],
      '05' => [['4.4.3',   '',    'systemerror',     false, false]],
      '06' => [['4.2.2',   '450', 'mailboxfull',     false, false]],
      '07' => [['4.4.1',   '',    'networkerror',    false, false]],
      '08' => [['5.9.220', '552', 'mailboxfull',     false,  true]],
      '09' => [['5.7.606', '550', 'blocked',         false, false]],
      '10' => [['5.9.221', '',    'suspend',         false,  true]],
      '11' => [['5.4.4',   '',    'notaccept',        true,  true]],
      '12' => [['5.4.4',   '',    'notaccept',        true,  true]],
      '13' => [['5.1.2',   '',    'hostunknown',      true,  true]],
      '14' => [['5.7.26',  '550', 'authfailure',     false, false]],
      '15' => [['5.7.509', '550', 'authfailure',     false, false]],
      '16' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '17' => [['5.1.1',   '550', 'userunknown',      true,  true],
               ['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '18' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '19' => [['4.7.0',   '421', 'badreputation',   false, false]],
      '20' => [['5.7.26',  '550', 'authfailure',     false, false]],
      '21' => [['5.1.1',   '',    'userunknown',      true,  true]],
      '22' => [['5.7.509', '550', 'authfailure',     false, false]],
      '23' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '24' => [['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '25' => [['5.2.2',   '552', 'mailboxfull',     false,  true],
               ['5.1.1',   '550', 'userunknown',      true,  true]],
    }
  end
end

