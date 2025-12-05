module LhostEngineTest::Public
  module DragonFly
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.7.26',  '550', 'authfailure',     false, false]],
      '02' => [['5.7.509', '550', 'authfailure',     false, false]],
      '03' => [['5.7.9',   '554', 'policyviolation', false, false]],
      '04' => [['5.0.912', '',    'hostunknown',      true,  true]],
      '05' => [['5.7.26',  '550', 'authfailure',     false, false]],
      '06' => [['5.7.25',  '550', 'requireptr',      false, false]],
      '07' => [['5.6.0',   '550', 'contenterror',    false, false]],
      '08' => [['5.2.3',   '552', 'exceedlimit',     false, false]],
      '09' => [['5.2.1',   '550', 'userunknown',      true,  true]],
      '10' => [['5.1.6',   '550', 'hasmoved',         true,  true]],
      '11' => [['5.1.2',   '550', 'hostunknown',      true,  true]],
      '12' => [['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '13' => [['5.3.0',   '554', 'mailererror',     false, false]],
      '14' => [['5.3.4',   '554', 'mesgtoobig',      false, false]],
      '15' => [['5.7.0',   '550', 'norelaying',      false,  true]],
      '16' => [['5.3.2',   '521', 'notaccept',        true,  true]],
      '17' => [['5.0.0',   '550', 'onhold',          false, false]],
      '18' => [['5.7.0',   '550', 'securityerror',   false, false]],
      '19' => [['5.7.1',   '551', 'securityerror',   false, false]],
      '20' => [['5.7.0',   '550', 'spamdetected',    false, false]],
      '21' => [['5.7.13',  '525', 'suspend',         false,  true]],
      '22' => [['5.1.3',   '501', 'userunknown',      true,  true]],
      '23' => [['5.3.0',   '554', 'systemerror',     false, false]],
      '24' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '25' => [['5.7.0',   '550', 'virusdetected',   false, false]],
      '26' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '27' => [['5.7.13',  '525', 'suspend',         false,  true]],
      '28' => [['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '29' => [['5.0.947', '',    'expired',         false, false]],
      '30' => [['5.0.947', '',    'expired',         false, false]],
    }
  end
end

