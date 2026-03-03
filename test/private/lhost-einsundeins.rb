module LhostEngineTest::Private
  module EinsUndEins
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1002'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1003'  => [['5.9.161', '',    'emailtoolarge',   false, 0]],
      '1004'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1005'  => [['5.4.1',   '550', 'userunknown',      true, 1]],
      '1006'  => [['5.4.1',   '550', 'userunknown',      true, 1]],
      '1007'  => [['5.4.1',   '550', 'userunknown',      true, 1]],
      '1008'  => [['5.4.1',   '550', 'userunknown',      true, 1]],
      '1009'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1010'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1011'  => [['5.4.1',   '550', 'userunknown',      true, 1]],
      '1012'  => [['5.4.1',   '550', 'userunknown',      true, 1]],
      '1013'  => [['5.4.1',   '550', 'userunknown',      true, 1]],
    }
  end
end

