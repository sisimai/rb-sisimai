module RhostEngineTest::Public
  module FrancePTT
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.5.0',   '550', 'userunknown',      true, 1]],
      '03' => [['5.2.0',   '550', 'spamdetected',    false, 0]],
      '04' => [['5.2.0',   '550', 'spamdetected',    false, 0]],
      '05' => [['5.5.0',   '550', 'suspend',         false, 1]],
      '06' => [['4.0.0',   '',    'blocked',         false, 0]],
      '07' => [['4.0.0',   '421', 'ratelimited',     false, 0]],
      '08' => [['4.2.0',   '421', 'systemerror',     false, 0]],
      '10' => [['5.5.0',   '550', 'blocked',         false, 0]],
      '11' => [['4.2.1',   '421', 'requireptr',      false, 0]],
      '12' => [['5.7.1',   '554', 'policyviolation', false, 0]],
    }
  end
end

