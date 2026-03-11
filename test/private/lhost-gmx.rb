module LhostEngineTest::Private
  module GMX
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.340', '',    'expired',         false, 0]],
      '1002'  => [['5.1.1',   '',    'userunknown',      true, 1]],
      '1003'  => [['5.2.2',   '',    'mailboxfull',     false, 1]],
      '1004'  => [['5.2.1',   '',    'userunknown',      true, 1],
                  ['5.2.2',   '',    'mailboxfull',     false, 1]],
    }
  end
end

