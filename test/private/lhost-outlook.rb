module LhostEngineTest::Private
  module Outlook
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1002'  => [['5.5.0',   '550', 'userunknown',      true,  true]],
      '1003'  => [['5.5.0',   '550', 'userunknown',      true,  true]],
      '1007'  => [['5.5.0',   '550', 'requireptr',      false, false]],
      '1008'  => [['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '1016'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1017'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1018'  => [['5.5.0',   '554', 'hostunknown',      true,  true]],
      '1019'  => [['5.1.1',   '550', 'userunknown',      true,  true],
                  ['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1023'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1024'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1025'  => [['5.5.0',   '550', 'userunknown',      true,  true]],
      '1026'  => [['5.5.0',   '550', 'userunknown',      true,  true]],
      '1027'  => [['5.5.0',   '550', 'userunknown',      true,  true]],
    }
  end
end

