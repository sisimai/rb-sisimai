module LhostEngineTest::Public
  module Gmail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '03' => [['5.7.0',   '554', 'filtered',        false,  true]],
      '04' => [['5.7.1',   '554', 'blocked',         false, false]],
      '05' => [['5.7.1',   '550', 'securityerror',   false, false]],
      '06' => [['4.2.2',   '450', 'mailboxfull',     false, false]],
      '07' => [['5.9.350', '500', 'failedstarttls',  false, false]],
      '08' => [['5.9.340', '',    'expired',         false, false]],
      '09' => [['4.9.340', '',    'expired',         false, false]],
      '10' => [['5.9.340', '',    'expired',         false, false]],
      '11' => [['5.9.340', '',    'expired',         false, false]],
      '15' => [['5.9.340', '',    'expired',         false, false]],
      '16' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '17' => [['4.9.340', '',    'expired',         false, false]],
      '18' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '19' => [['5.9.220', '',    'mailboxfull',     false, false]],
    }
  end
end

