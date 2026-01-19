module LhostEngineTest::Public
  module IMailServer
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.9.213', '',    'userunknown',      true,  true]],
      '02' => [['5.9.220', '',    'mailboxfull',     false, false]],
      '03' => [['5.9.213', '',    'userunknown',      true,  true]],
      '04' => [['5.9.340', '',    'expired',         false, false]],
      '06' => [['5.9.164', '550', 'spamdetected',    false, false]],
    }
  end
end

