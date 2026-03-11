module LhostEngineTest::Public
  module Mimecast
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.4.1',   '',    'userunknown',      true, 1]],
      '02' => [['5.7.54',  '550', 'norelaying',      false, 1]],
    }
  end
end

