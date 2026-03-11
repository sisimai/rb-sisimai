module LhostEngineTest::Public
  module X3
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.3.0',   '553', 'userunknown',      true, 1]],
      '02' => [['5.9.340', '',    'expired',         false, 0]],
      '03' => [['5.3.0',   '553', 'userunknown',      true, 1]],
      '05' => [['5.9.300', '',    'undefined',       false, 0]],
      '06' => [['5.2.2',   '552', 'mailboxfull',     false, 1]],
    }
  end
end

