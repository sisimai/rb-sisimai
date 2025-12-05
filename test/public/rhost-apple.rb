module RhostEngineTest::Public
  module Apple
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.6',   '550', 'hasmoved',         true,  true]],
      '02' => [['5.7.1',   '554', 'authfailure',     false, false]],
      '03' => [['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '04' => [['5.1.1',   '550', 'suspend',         false,  true]],
      '05' => [['5.1.1',   '550', 'userunknown',      true,  true]],
    }
  end
end

