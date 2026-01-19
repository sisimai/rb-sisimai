module LhostEngineTest::Public
  module MFILTER
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.210', '550', 'filtered',        false,  true]],
      '02' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '03' => [['5.9.210', '550', 'filtered',        false,  true]],
      '04' => [['5.4.1',   '550', 'rejected',        false, false]],
      '05' => [['4.3.1',   '452', 'systemfull',      false, false]],
    }
  end
end

