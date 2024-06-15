module LhostEngineTest::Public
  module DragonFly
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.7.26',  '550', 'authfailure',     false]],
      '02' => [['5.7.509', '550', 'authfailure',     false]],
      '03' => [['5.7.9',   '554', 'policyviolation', false]],
      '04' => [['5.0.912', '',    'hostunknown',     true]],
      '05' => [['5.7.26',  '550', 'authfailure',     false]],
      '06' => [['5.7.25',  '550', 'requireptr',      false]],
      '07' => [['5.6.0',   '550', 'contenterror',    false]],
      '08' => [['5.2.3',   '552', 'exceedlimit',     false]],
      '09' => [['5.2.1',   '550', 'userunknown',     true]],
      '10' => [['5.1.6',   '550', 'hasmoved',        true]],
      '11' => [['5.1.2',   '550', 'hostunknown',     true]],
      '12' => [['5.2.2',   '552', 'mailboxfull',     false]],
      '13' => [['5.3.0',   '554', 'mailererror',     false]],
      '14' => [['5.3.4',   '554', 'mesgtoobig',      false]],
      '15' => [['5.7.0',   '550', 'norelaying',      false]],
      '16' => [['5.3.2',   '521', 'notaccept',       true]],
      '17' => [['5.0.0',   '550', 'onhold',          false]],
      '18' => [['5.7.0',   '550', 'securityerror',   false]],
      '19' => [['5.7.1',   '551', 'securityerror',   false]],
      '20' => [['5.7.0',   '550', 'spamdetected',    false]],
      '21' => [['5.7.13',  '525', 'suspend',         false]],
      '22' => [['5.1.3',   '501', 'userunknown',     true]],
      '23' => [['5.3.0',   '554', 'systemerror',     false]],
      '24' => [['5.1.1',   '550', 'userunknown',     true]],
      '25' => [['5.7.0',   '550', 'virusdetected',   false]],
      '26' => [['5.1.1',   '550', 'userunknown',     true]],
      '27' => [['5.7.13',  '525', 'suspend',         false]],
      '28' => [['5.2.2',   '552', 'mailboxfull',     false]],
    }
  end
end

