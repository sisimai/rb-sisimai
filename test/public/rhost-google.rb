module RhostEngineTest::Public
  module Google
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.2.1',   '550', 'suspend',         false, 1]],
      '02' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '03' => [['5.7.26',  '550', 'authfailure',     false, 0]],
      '04' => [['5.7.26',  '550', 'authfailure',     false, 0]],
      '05' => [['5.2.2',   '552', 'mailboxfull',     false, 1]],
      '06' => [['5.7.25',  '550', 'requireptr',      false, 0]],
      '07' => [['5.2.1',   '550', 'suspend',         false, 1]],
      '08' => [['5.7.1',   '550', 'notcompliantrfc', false, 0]],
    }
  end
end

