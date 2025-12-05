module LhostEngineTest::Private
  module MFILTER
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.0.910', '550', 'filtered',        false,  true]],
      '1002'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1003'  => [['5.0.910', '550', 'filtered',        false,  true]],
      '1004'  => [['5.0.910', '550', 'filtered',        false,  true]],
      '1005'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1006'  => [['5.0.910', '550', 'filtered',        false,  true]],
      '1007'  => [['5.0.911', '550', 'userunknown',      true,  true]],
      '1008'  => [['5.4.1',   '550', 'rejected',        false, false]],
      '1009'  => [['5.4.1',   '550', 'rejected',        false, false]],
      '1010'  => [['4.3.1',   '452', 'systemfull',      false, false]],
      '1011'  => [['5.6.0',   '550', 'spamdetected',    false, false]],
      '1012'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '1013'  => [['5.0.910', '550', 'filtered',        false,  true]],
      '1014'  => [['5.1.1',   '550', 'userunknown',      true,  true]],
    }
  end
end

