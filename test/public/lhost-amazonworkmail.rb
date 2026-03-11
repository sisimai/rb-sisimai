module LhostEngineTest::Public
  module AmazonWorkMail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.2.1',   '550', 'filtered',        false, 1]],
      '03' => [['5.3.5',   '550', 'systemerror',     false, 0]],
      '04' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '05' => [['4.4.2',   '421', 'expired',         false, 0]],
      '07' => [['4.4.2',   '421', 'expired',         false, 0]],
      '08' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
    }
  end
end

