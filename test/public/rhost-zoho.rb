module RhostEngineTest::Public
  module Zoho
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.7.7',   '554', 'policyviolation', false, 0]],
      '03' => [['5.7.1',   '554', 'rejected',        false, 0]],
      '04' => [['5.4.1',   '',    'rejected',        false, 0]],
    }
  end
end

