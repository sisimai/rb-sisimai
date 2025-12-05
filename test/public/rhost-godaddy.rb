module RhostEngineTest::Public
  module GoDaddy
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '02' => [['5.1.3',   '553', 'blocked',         false, false]],
      '03' => [['5.1.1',   '550', 'speeding',        false, false]],
    }
  end
end

