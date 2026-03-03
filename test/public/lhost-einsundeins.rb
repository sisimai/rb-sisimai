module LhostEngineTest::Public
  module EinsUndEins
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '02' => [['5.9.161', '',    'emailtoolarge',   false, 0]],
      '03' => [['5.2.0',   '550', 'spamdetected',    false, 0]],
    }
  end
end

