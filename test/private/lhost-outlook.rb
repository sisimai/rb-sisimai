module LhostEngineTest::Private
  module Outlook
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1002'  => [['5.5.0',   '550', 'userunknown',      true, 1]],
      '1003'  => [['5.5.0',   '550', 'userunknown',      true, 1]],
      '1007'  => [['5.5.0',   '550', 'requireptr',      false, 0]],
      '1008'  => [['5.2.2',   '552', 'mailboxfull',     false, 1]],
      '1016'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1017'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1018'  => [['5.5.0',   '554', 'hostunknown',      true, 1]],
      '1019'  => [['5.1.1',   '550', 'userunknown',      true, 1],
                  ['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1023'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1024'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1025'  => [['5.5.0',   '550', 'userunknown',      true, 1]],
      '1026'  => [['5.5.0',   '550', 'userunknown',      true, 1]],
      '1027'  => [['5.5.0',   '550', 'userunknown',      true, 1]],
    }
  end
end

