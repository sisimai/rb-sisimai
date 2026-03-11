module LhostEngineTest::Private
  module SurfControl
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.0.0',   '550', 'filtered',        false, 1]],
      '1002'  => [['5.0.0',   '550', 'filtered',        false, 1]],
      '1003'  => [['5.0.0',   '550', 'filtered',        false, 1]],
      '1004'  => [['5.0.0',   '554', 'systemerror',     false, 0]],
      '1005'  => [['5.0.0',   '554', 'systemerror',     false, 0]],
    }
  end
end

