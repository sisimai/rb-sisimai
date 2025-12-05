module LhostEngineTest::Private
  module MailFoundry
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '1001'  => [['5.0.910', '550', 'filtered',        false,  true]],
      '1002'  => [['5.1.1',   '552', 'mailboxfull',     false,  true]],
      '1003'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1004'  => [['5.0.910', '550', 'filtered',        false,  true]],
      '1005'  => [['5.1.1',   '552', 'mailboxfull',     false,  true]],
    }
  end
end

