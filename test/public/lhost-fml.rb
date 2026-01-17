module LhostEngineTest::Public
  module FML
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '02' => [['5.9.110', '',    'rejected',        false, false]],
      '03' => [['5.9.162', '',    'notcompliantrfc', false, false]],
    }
  end
end

