module LhostEngineTest::Private
  module MailMarshal
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.3.0',   '553', 'filtered',        false, 1],
                  ['5.3.0',   '553', 'filtered',        false, 1]],
      '1002'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
    }
  end
end

