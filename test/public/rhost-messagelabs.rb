module RhostEngineTest::Public
  module MessageLabs
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.0',   '550', 'securityerror',   false, false]],
      '02' => [['5.0.0',   '550', 'userunknown',      true,  true]],
      '03' => [['5.0.0',   '',    'onhold',          false, false]],
    }
  end
end

