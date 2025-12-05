module LhostEngineTest::Private
  module MailRu
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.0.911', '',    'userunknown',      true,  true]],
      '1002'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1003'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1004'  => [['5.2.2',   '550', 'mailboxfull',     false,  true],
                  ['5.2.1',   '550', 'userunknown',      true,  true]],
      '1005'  => [['5.0.910', '',    'filtered',        false, false]],
      '1006'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1007'  => [['5.0.911', '',    'userunknown',      true,  true]],
      '1008'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1009'  => [['5.0.910', '550', 'filtered',        false,  true]],
      '1010'  => [['5.0.911', '550', 'userunknown',      true,  true]],
      '1011'  => [['5.1.8',   '501', 'rejected',        false, false]],
    }
  end
end

