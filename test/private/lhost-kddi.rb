module LhostEngineTest::Private
  module KDDI
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.0.922', '',    'mailboxfull',     false, false]],
      '1002'  => [['5.0.922', '',    'mailboxfull',     false, false]],
      '1003'  => [['5.0.922', '',    'mailboxfull',     false, false]],
    }
  end
end

