module LhostEngineTest::Public
  module AmazonSES
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.7.1',   '550', 'securityerror',   false, false]],
      '02' => [['5.3.0',   '550', 'filtered',        false,  true]],
      '03' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '05' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '06' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '07' => [['5.7.6',   '550', 'securityerror',   false, false]],
      '08' => [['5.7.9',   '550', 'securityerror',   false, false]],
      '09' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '10' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '11' => [['',        '',    'feedback',        false,  true, 'abuse']],
      '12' => [['2.6.0',   '250', 'delivered',       false, false]],
      '13' => [['2.6.0',   '250', 'delivered',       false, false]],
      '14' => [['5.7.1',   '554', 'blocked',         false, false]],
      '15' => [['5.7.1',   '554', 'blocked',         false, false]],
      '16' => [['5.7.1',   '521', 'blocked',         false, false]],
      '17' => [['4.4.2',   '421', 'expired',         false, false]],
      '18' => [['5.4.4',   '550', 'hostunknown',      true,  true]],
      '19' => [['5.7.1',   '550', 'suspend',         false,  true]],
      '20' => [['5.2.1',   '550', 'suspend',         false,  true]],
      '21' => [['5.7.1',   '554', 'norelaying',      false,  true]],
    }
  end
end

