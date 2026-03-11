module LhostEngineTest::Public
  module Courier
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.0.0',   '550', 'filtered',        false, 1]],
      '03' => [['5.7.1',   '550', 'rejected',        false, 0]],
      '04' => [['5.0.0',   '',    'hostunknown',      true, 1]],
    }
  end
end

