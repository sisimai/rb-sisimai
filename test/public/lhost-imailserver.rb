module LhostEngineTest::Public
  module IMailServer
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.911', '',    'userunknown',      true,  true]],
      '02' => [['5.0.922', '',    'mailboxfull',     false, false]],
      '03' => [['5.0.911', '',    'userunknown',      true,  true]],
      '04' => [['5.0.947', '',    'expired',         false, false]],
      '06' => [['5.0.980', '550', 'spamdetected',    false, false]],
    }
  end
end

