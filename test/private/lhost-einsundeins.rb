module LhostEngineTest::Private
  module EinsUndEins
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.220', '',    'mailboxfull',     false, false]],
      '1002'  => [['5.9.220', '',    'mailboxfull',     false, false]],
      '1003'  => [['5.9.161', '',    'emailtoolarge',   false, false]],
      '1004'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1005'  => [['5.4.1',   '550', 'userunknown',      true,  true]],
      '1006'  => [['5.4.1',   '550', 'userunknown',      true,  true]],
      '1007'  => [['5.4.1',   '550', 'userunknown',      true,  true]],
      '1008'  => [['5.4.1',   '550', 'userunknown',      true,  true]],
      '1009'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1010'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1011'  => [['5.4.1',   '550', 'userunknown',      true,  true]],
      '1012'  => [['5.4.1',   '550', 'userunknown',      true,  true]],
      '1013'  => [['5.4.1',   '550', 'userunknown',      true,  true]],
    }
  end
end

