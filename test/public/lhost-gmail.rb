module LhostEngineTest::Public
  module Gmail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '03' => [['5.7.0',   '554', 'filtered',        false, 1]],
      '04' => [['5.7.1',   '554', 'blocked',         false, 0]],
      '05' => [['5.7.1',   '550', 'securityerror',   false, 0]],
      '06' => [['4.2.2',   '450', 'mailboxfull',     false, 0]],
      '07' => [['5.9.350', '500', 'failedstarttls',  false, 0]],
      '08' => [['5.9.340', '',    'expired',         false, 0]],
      '09' => [['4.9.340', '',    'expired',         false, 0]],
      '10' => [['5.9.340', '',    'expired',         false, 0]],
      '11' => [['5.9.340', '',    'expired',         false, 0]],
      '15' => [['5.9.340', '',    'expired',         false, 0]],
      '16' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '17' => [['4.9.340', '',    'expired',         false, 0]],
      '18' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '19' => [['5.9.220', '',    'mailboxfull',     false, 0]],
    }
  end
end

