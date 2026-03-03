module LhostEngineTest::Public
  module IMailServer
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.213', '',    'userunknown',      true, 1]],
      '02' => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '03' => [['5.9.213', '',    'userunknown',      true, 1]],
      '04' => [['5.9.340', '',    'expired',         false, 0]],
      '06' => [['5.9.164', '550', 'spamdetected',    false, 0]],
    }
  end
end

