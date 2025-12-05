module RhostEngineTest::Public
  module Mimecast
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.0',   '554', 'policyviolation', false, false]],
      '02' => [['5.0.0',   '554', 'spamdetected',    false, false]],
    }
  end
end

