module RhostEngineTest::Public
  module Mimecast
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.0',   '554', 'policyviolation', false, 0]],
      '02' => [['5.0.0',   '554', 'spamdetected',    false, 0]],
    }
  end
end

