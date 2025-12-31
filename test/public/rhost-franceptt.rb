module RhostEngineTest::Public
  module FrancePTT
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.5.0',   '550', 'userunknown',      true,  true]],
      '03' => [['5.2.0',   '550', 'spamdetected',    false, false]],
      '04' => [['5.2.0',   '550', 'spamdetected',    false, false]],
      '05' => [['5.5.0',   '550', 'suspend',         false,  true]],
      '06' => [['4.0.0',   '',    'blocked',         false, false]],
      '07' => [['4.0.0',   '421', 'ratelimited',     false, false]],
      '08' => [['4.2.0',   '421', 'systemerror',     false, false]],
      '10' => [['5.5.0',   '550', 'blocked',         false, false]],
      '11' => [['4.2.1',   '421', 'requireptr',      false, false]],
      '12' => [['5.7.1',   '554', 'policyviolation', false, false]],
    }
  end
end

