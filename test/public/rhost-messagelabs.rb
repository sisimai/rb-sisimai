module RhostEngineTest::Public
  module MessageLabs
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.0',   '550', 'securityerror',   false, 0]],
      '02' => [['5.0.0',   '550', 'userunknown',      true, 1]],
      '03' => [['5.0.0',   '',    'onhold',          false, 0]],
    }
  end
end

