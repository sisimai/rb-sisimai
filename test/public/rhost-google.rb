module RhostEngineTest::Public
  module Google
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.2.1',   '550', 'suspend',         false,  true]],
      '02' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '03' => [['5.7.26',  '550', 'authfailure',     false, false]],
      '04' => [['5.7.26',  '550', 'authfailure',     false, false]],
      '05' => [['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '06' => [['5.7.25',  '550', 'requireptr',      false, false]],
      '07' => [['5.2.1',   '550', 'suspend',         false,  true]],
      '08' => [['5.7.1',   '550', 'notcompliantrfc', false, false]],
    }
  end
end

