module RhostEngineTest::Public
  module Apple
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.6',   '550', 'hasmoved',        true]],
      '02' => [['5.7.1',   '554', 'authfailure',     false]],
      '03' => [['5.2.2',   '552', 'mailboxfull',     false]],
      '04' => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

