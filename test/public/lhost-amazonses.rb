  module LhostEngineTest::Public
  module AmazonSES
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.7.1',   '550', 'securityerror',   false, 0]],
      '02' => [['5.3.0',   '550', 'filtered',        false, 1]],
      '03' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '05' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '06' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '07' => [['5.7.6',   '550', 'securityerror',   false, 0]],
      '08' => [['5.7.9',   '550', 'securityerror',   false, 0]],
      '09' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '10' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '11' => [['',        '',    'feedback',        false, 1, 'abuse']],
      '12' => [['2.6.0',   '250', 'delivered',       false, 0]],
      '13' => [['2.6.0',   '250', 'delivered',       false, 0]],
      '14' => [['5.7.1',   '554', 'blocked',         false, 0]],
      '15' => [['5.7.1',   '554', 'blocked',         false, 0]],
      '16' => [['5.7.1',   '521', 'blocked',         false, 0]],
      '17' => [['4.4.2',   '421', 'expired',         false, 0]],
      '18' => [['5.4.4',   '550', 'hostunknown',      true, 1]],
      '19' => [['5.7.1',   '550', 'suspend',         false, 1]],
      '20' => [['5.2.1',   '550', 'suspend',         false, 1]],
      '21' => [['5.7.1',   '554', 'norelaying',      false, 1]],
    }
  end
end

