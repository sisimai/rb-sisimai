module RhostEngineTest::Public
  module Zoho
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',       true,  true]],
      '02' => [['5.7.7',   '554', 'policyviolation', false, false]],
      '03' => [['5.7.1',   '554', 'rejected',        false, false]],
      '04' => [['5.4.1',   '',    'rejected',        false, false]],
    }
  end
end

