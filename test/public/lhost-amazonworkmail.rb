module LhostEngineTest::Public
  module AmazonWorkMail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.2.1',   '550', 'filtered',        false,  true]],
      '03' => [['5.3.5',   '550', 'systemerror',     false, false]],
      '04' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '05' => [['4.4.2',   '421', 'expired',         false, false]],
      '07' => [['4.4.2',   '421', 'expired',         false, false]],
      '08' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
    }
  end
end

