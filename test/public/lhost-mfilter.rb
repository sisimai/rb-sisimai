module LhostEngineTest::Public
  module MFILTER
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.210', '550', 'filtered',        false, 1]],
      '02' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '03' => [['5.9.210', '550', 'filtered',        false, 1]],
      '04' => [['5.4.1',   '550', 'rejected',        false, 0]],
      '05' => [['4.3.1',   '452', 'systemfull',      false, 0]],
    }
  end
end

