module LhostEngineTest::Public
  module MessagingServer
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.2.0',   '',    'mailboxfull',     false, 1]],
      '03' => [['5.7.1',   '550', 'filtered',        false, 1],
               ['5.7.1',   '550', 'filtered',        false, 1]],
      '04' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '05' => [['5.4.4',   '',    'hostunknown',      true, 1]],
      '06' => [['5.2.1',   '550', 'filtered',        false, 1]],
      '07' => [['4.4.7',   '',    'expired',         false, 0]],
      '08' => [['5.0.0',   '550', 'filtered',        false, 1]],
      '09' => [['5.0.0',   '550', 'userunknown',      true, 1]],
      '10' => [['5.1.10',  '',    'notaccept',        true, 1]],
      '11' => [['5.1.8',   '501', 'rejected',        false, 0]],
      '12' => [['4.2.2',   '',    'mailboxfull',     false, 0]],
    }
  end
end

