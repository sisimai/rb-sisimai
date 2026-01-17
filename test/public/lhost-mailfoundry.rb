module LhostEngineTest::Public
  module MailFoundry
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.210', '550', 'filtered',        false,  true]],
      '02' => [['5.1.1',   '552', 'mailboxfull',     false,  true]],
    }
  end
end

