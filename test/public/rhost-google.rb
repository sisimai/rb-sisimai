module RhostEngineTest::Public
  module Google
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.2.1',   '550', 'suspend',         false]],
      '02' => [['5.1.1',   '550', 'userunknown',     true]],
      '03' => [['5.7.26',  '550', 'authfailure',     false]],
      '04' => [['5.7.26',  '550', 'authfailure',     false]],
      '05' => [['5.2.2',   '552', 'mailboxfull',     false]],
      '06' => [['5.7.25',  '550', 'requireptr',      false]],
      '07' => [['5.2.1',   '550', 'suspend',         false]],
    }
  end
end

