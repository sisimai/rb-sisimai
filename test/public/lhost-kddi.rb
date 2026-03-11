module LhostEngineTest::Public
  module KDDI
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '02' => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '03' => [['5.9.220', '',    'mailboxfull',     false, 0]],
    }
  end
end

