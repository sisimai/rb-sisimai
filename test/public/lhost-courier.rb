module LhostEngineTest::Public
  module Courier
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.0.0',   '550', 'filtered',        false,  true]],
      '03' => [['5.7.1',   '550', 'rejected',        false, false]],
      '04' => [['5.0.0',   '',    'hostunknown',      true,  true]],
    }
  end
end

