module LhostEngineTest::Private
  module MFILTER
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1002'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1003'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1004'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1005'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1006'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1007'  => [['5.9.213', '550', 'userunknown',      true, 1]],
      '1008'  => [['5.4.1',   '550', 'rejected',        false, 0]],
      '1009'  => [['5.4.1',   '550', 'rejected',        false, 0]],
      '1010'  => [['4.3.1',   '452', 'systemfull',      false, 0]],
      '1011'  => [['5.6.0',   '550', 'spamdetected',    false, 0]],
      '1012'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1013'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1014'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
    }
  end
end

