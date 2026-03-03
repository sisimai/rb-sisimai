module RhostEngineTest::Public
  module NTTDOCOMO
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.2.0',   '550', 'filtered',        false, 1]],
      '02' => [['5.0.0',   '550', 'userunknown',      true, 1]],
      '03' => [['5.0.0',   '550', 'userunknown',      true, 1]],
    }
  end
end

