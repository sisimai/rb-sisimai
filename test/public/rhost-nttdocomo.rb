module RhostEngineTest::Public
  module NTTDOCOMO
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.2.0',   '550', 'filtered',        false,  true]],
      '02' => [['5.0.0',   '550', 'userunknown',      true,  true]],
      '03' => [['5.0.0',   '550', 'userunknown',      true,  true]],
    }
  end
end

