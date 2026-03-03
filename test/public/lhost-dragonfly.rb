module LhostEngineTest::Public
  module DragonFly
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.7.26',  '550', 'authfailure',     false, 0]],
      '02' => [['5.7.509', '550', 'authfailure',     false, 0]],
      '03' => [['5.7.9',   '554', 'policyviolation', false, 0]],
      '04' => [['5.9.212', '',    'hostunknown',      true, 1]],
      '05' => [['5.7.26',  '550', 'authfailure',     false, 0]],
      '06' => [['5.7.25',  '550', 'requireptr',      false, 0]],
      '07' => [['5.6.0',   '550', 'contenterror',    false, 0]],
      '08' => [['5.2.3',   '552', 'emailtoolarge',   false, 0]],
      '09' => [['5.2.1',   '550', 'userunknown',      true, 1]],
      '10' => [['5.1.6',   '550', 'hasmoved',         true, 1]],
      '11' => [['5.1.2',   '550', 'hostunknown',      true, 1]],
      '12' => [['5.2.2',   '552', 'mailboxfull',     false, 1]],
      '13' => [['5.3.0',   '554', 'mailererror',     false, 0]],
      '14' => [['5.3.4',   '554', 'emailtoolarge',   false, 0]],
      '15' => [['5.7.0',   '550', 'norelaying',      false, 1]],
      '16' => [['5.3.2',   '521', 'notaccept',        true, 1]],
      '17' => [['5.0.0',   '550', 'onhold',          false, 0]],
      '18' => [['5.7.0',   '550', 'securityerror',   false, 0]],
      '19' => [['5.7.1',   '551', 'securityerror',   false, 0]],
      '20' => [['5.7.0',   '550', 'spamdetected',    false, 0]],
      '21' => [['5.7.13',  '525', 'suspend',         false, 1]],
      '22' => [['5.1.3',   '501', 'userunknown',      true, 1]],
      '23' => [['5.3.0',   '554', 'systemerror',     false, 0]],
      '24' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '25' => [['5.7.0',   '550', 'virusdetected',   false, 0]],
      '26' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '27' => [['5.7.13',  '525', 'suspend',         false, 1]],
      '28' => [['5.2.2',   '552', 'mailboxfull',     false, 1]],
      '29' => [['5.9.340', '',    'expired',         false, 0]],
      '30' => [['5.9.340', '',    'expired',         false, 0]],
    }
  end
end

