module LhostEngineTest::Private
  module Aol
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.4.4',   '',    'hostunknown',      true,  true]],
      '1002'  => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '1003'  => [['5.2.2',   '550', 'mailboxfull',     false,  true],
                  ['5.1.1',   '550', 'userunknown',      true,  true]],
      '1004'  => [['5.2.2',   '550', 'mailboxfull',     false,  true],
                  ['5.1.1',   '550', 'userunknown',      true,  true]],
      '1005'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1006'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1007'  => [['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '1008'  => [['5.7.1',   '554', 'filtered',        false,  true]],
      '1009'  => [['5.7.1',   '554', 'policyviolation', false, false]],
      '1010'  => [['5.7.1',   '554', 'filtered',        false,  true]],
      '1011'  => [['5.7.1',   '554', 'filtered',        false,  true]],
      '1012'  => [['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '1013'  => [['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '1014'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
    }
  end
end

