module LhostEngineTest::Public
  module GMX
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.2.2',   '',    'mailboxfull',     false,  true]],
      '02' => [['5.1.1',   '',    'userunknown',      true,  true]],
      '03' => [['5.2.1',   '',    'userunknown',      true,  true],
               ['5.2.2',   '',    'mailboxfull',     false,  true]],
      '04' => [['5.0.947', '',    'expired',         false, false]],
    }
  end
end

