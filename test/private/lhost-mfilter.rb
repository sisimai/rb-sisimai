module LhostEngineTest::Private
  module MFILTER
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '1001'  => [['5.0.910', '550', 'filtered',        false]],
      '1002'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1003'  => [['5.0.910', '550', 'filtered',        false]],
      '1004'  => [['5.0.910', '550', 'filtered',        false]],
      '1005'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1006'  => [['5.0.910', '550', 'filtered',        false]],
      '1007'  => [['5.0.911', '550', 'userunknown',     true]],
      '1008'  => [['5.4.1',   '550', 'rejected',        false]],
      '1009'  => [['5.4.1',   '550', 'rejected',        false]],
      '1010'  => [['4.3.1',   '452', 'systemfull',      false]],
      '1011'  => [['5.6.0',   '550', 'spamdetected',    false]],
      '1012'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1013'  => [['5.0.910', '550', 'filtered',        false]],
      '1014'  => [['5.1.1',   '550', 'userunknown',     true]],
    }
  end
end

