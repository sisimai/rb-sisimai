module LhostEngineTest::Public
  module KDDI
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.922', '',    'mailboxfull',     false, false]],
      '02' => [['5.0.922', '',    'mailboxfull',     false, false]],
      '03' => [['5.0.922', '',    'mailboxfull',     false, false]],
    }
  end
end

