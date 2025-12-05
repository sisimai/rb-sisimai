module LhostEngineTest::Private
  module Courier
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001' => [['5.0.0',   '550', 'userunknown',      true,  true]],
      '1002' => [['5.0.0',   '550', 'userunknown',      true,  true]],
      '1003' => [['5.7.1',   '550', 'rejected',        false, false]],
      '1004' => [['5.0.0',   '550', 'userunknown',      true,  true]],
      '1005' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1006' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1007' => [['5.0.0',   '550', 'userunknown',      true,  true]],
      '1008' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1009' => [['5.0.0',   '550', 'filtered',        false,  true]],
      '1010' => [['5.7.1',   '550', 'rejected',        false, false]],
      '1011' => [['5.0.0',   '',    'hostunknown',      true,  true]],
      '1012' => [['5.0.0',   '',    'hostunknown',      true,  true]],
    }
  end
end

