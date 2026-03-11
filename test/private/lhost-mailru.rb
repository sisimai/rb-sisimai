module LhostEngineTest::Private
  module MailRu
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.213', '',    'userunknown',      true, 1]],
      '1002'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1003'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1004'  => [['5.2.2',   '550', 'mailboxfull',     false, 1],
                  ['5.2.1',   '550', 'userunknown',      true, 1]],
      '1005'  => [['5.9.210', '',    'filtered',        false, 0]],
      '1006'  => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '1007'  => [['5.9.213', '',    'userunknown',      true, 1]],
      '1008'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1009'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1010'  => [['5.9.213', '550', 'userunknown',      true, 1]],
      '1011'  => [['5.1.8',   '501', 'rejected',        false, 0]],
    }
  end
end

