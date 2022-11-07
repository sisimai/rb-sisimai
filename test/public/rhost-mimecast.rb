module RhostEngineTest::Public
  module Mimecast
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.0.0',   '554', 'policyviolation', false]],
      '02' => [['5.0.0',   '554', 'virusdetected',   false]],
    }
  end
end

