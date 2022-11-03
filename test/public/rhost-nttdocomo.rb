module RhostEngineTest::Public
  module NTTDOCOMO
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.2.0',   '550', 'filtered',        false]],
      '02' => [['5.0.0',   '550', 'rejected',        false]],
      '03' => [['5.0.0',   '550', 'rejected',        false]],
    }
  end
end

