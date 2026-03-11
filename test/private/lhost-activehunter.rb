module LhostEngineTest::Private
  module Activehunter
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1002'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1003'  => [['5.3.0',   '553', 'filtered',        false, 1]],
      '1004'  => [['5.7.17',  '550', 'filtered',        false, 1]],
      '1005'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1006'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1007'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1008'  => [['5.9.210', '550', 'filtered',        false, 1]],
      '1009'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1010'  => [['5.3.0',   '553', 'filtered',        false, 1]],
      '1011'  => [['5.7.17',  '550', 'filtered',        false, 1]],
      '1012'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
    }
  end
end

