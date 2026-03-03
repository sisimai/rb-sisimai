module LhostEngineTest::Private
  module ReceivingSES
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.2.3',   '552', 'emailtoolarge',  false, 0]],
    }
  end
end

