module LhostEngineTest::Public
  module Mimecast
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.4.1',   '',    'userunknown',     true]],
      '02' => [['5.7.54',  '550', 'norelaying',      false]],
    }
  end
end

