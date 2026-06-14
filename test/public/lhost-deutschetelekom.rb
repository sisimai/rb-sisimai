module LhostEngineTest::Public
  module DeutscheTelekom
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.2.2',   '552', 'mailboxfull',     false, -1]],
      '02' => [['5.2.2',   '552', 'mailboxfull',     false, -1],
               ['5.1.1',   '550', 'userunknown',      true, -1]],
    }
  end
end

