module LhostEngineTest::Public
  module X2
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.210', '',    'filtered',        false, 0]],
      '02' => [['5.9.210', '',    'filtered',        false, 0],
               ['5.9.221', '',    'suspend',         false, 1],
               ['5.9.210', '',    'filtered',        false, 0]],
      '03' => [['5.9.340', '',    'expired',         false, 0]],
      '04' => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '05' => [['4.1.9',   '',    'expired',         false, 0]],
      '06' => [['4.4.1',   '',    'networkerror',    false, 0]],
      '07' => [['5.4.14',  '554', 'networkerror',    false, 0]],
    }
  end
end

