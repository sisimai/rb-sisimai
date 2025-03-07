module LhostEngineTest::Private
  module Outlook
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '1002'  => [['5.5.0',   '550', 'userunknown',     true]],
      '1003'  => [['5.5.0',   '550', 'userunknown',     true]],
      '1007'  => [['5.5.0',   '550', 'requireptr',      false]],
      '1008'  => [['5.2.2',   '552', 'mailboxfull',     false]],
      '1016'  => [['5.2.2',   '550', 'mailboxfull',     false]],
      '1017'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1018'  => [['5.5.0',   '554', 'hostunknown',     true]],
      '1019'  => [['5.1.1',   '550', 'userunknown',     true],
                  ['5.2.2',   '550', 'mailboxfull',     false]],
      '1023'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1024'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1025'  => [['5.5.0',   '550', 'userunknown',     true]],
      '1026'  => [['5.5.0',   '550', 'userunknown',     true]],
      '1027'  => [['5.5.0',   '550', 'userunknown',     true]],
    }
  end
end

