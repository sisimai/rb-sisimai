module LhostEngineTest::Public
  module GMX
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.2.2',   '',    'mailboxfull',     false, 1]],
      '02' => [['5.1.1',   '',    'userunknown',      true, 1]],
      '03' => [['5.2.1',   '',    'userunknown',      true, 1],
               ['5.2.2',   '',    'mailboxfull',     false, 1]],
      '04' => [['5.9.340', '',    'expired',         false, 0]],
    }
  end
end

