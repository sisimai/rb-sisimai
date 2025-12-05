module LhostEngineTest::Public
  module X2
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.910', '',    'filtered',        false, false]],
      '02' => [['5.0.910', '',    'filtered',        false, false],
               ['5.0.921', '',    'suspend',         false,  true],
               ['5.0.910', '',    'filtered',        false, false]],
      '03' => [['5.0.947', '',    'expired',         false, false]],
      '04' => [['5.0.922', '',    'mailboxfull',     false, false]],
      '05' => [['4.1.9',   '',    'expired',         false, false]],
      '06' => [['4.4.1',   '',    'expired',         false, false]],
      '07' => [['5.4.14',  '554', 'networkerror',    false, false]],
    }
  end
end

