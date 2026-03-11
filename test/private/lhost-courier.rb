module LhostEngineTest::Private
  module Courier
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001' => [['5.0.0',   '550', 'userunknown',      true, 1]],
      '1002' => [['5.0.0',   '550', 'userunknown',      true, 1]],
      '1003' => [['5.7.1',   '550', 'rejected',        false, 0]],
      '1004' => [['5.0.0',   '550', 'userunknown',      true, 1]],
      '1005' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1006' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1007' => [['5.0.0',   '550', 'userunknown',      true, 1]],
      '1008' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1009' => [['5.0.0',   '550', 'filtered',        false, 1]],
      '1010' => [['5.7.1',   '550', 'rejected',        false, 0]],
      '1011' => [['5.0.0',   '',    'hostunknown',      true, 1]],
      '1012' => [['5.0.0',   '',    'hostunknown',      true, 1]],
    }
  end
end

