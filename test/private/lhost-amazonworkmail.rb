module LhostEngineTest::Private
  module AmazonWorkMail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01001' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '01002' => [['5.2.1',   '550', 'filtered',        false, 1]],
      '01003' => [['5.3.5',   '550', 'systemerror',     false, 0]],
      '01004' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '01005' => [['4.4.2',   '421', 'expired',         false, 0]],
      '01006' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
    }
  end
end

