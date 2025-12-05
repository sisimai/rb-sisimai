module LhostEngineTest::Public
  module SurfControl
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.0',   '550', 'filtered',        false,  true]],
      '02' => [['5.0.0',   '554', 'systemerror',     false, false]],
      '03' => [['5.0.0',   '554', 'systemerror',     false, false]],
    }
  end
end

