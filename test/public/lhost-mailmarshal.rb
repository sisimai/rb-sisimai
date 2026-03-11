module LhostEngineTest::Public
  module MailMarshal
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '02' => [['5.1.1',   '550', 'userunknown',      true, 1]],
    }
  end
end

