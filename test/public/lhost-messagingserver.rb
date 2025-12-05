module LhostEngineTest::Public
  module MessagingServer
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.2.0',   '',    'mailboxfull',     false,  true]],
      '03' => [['5.7.1',   '550', 'filtered',        false,  true],
               ['5.7.1',   '550', 'filtered',        false,  true]],
      '04' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '05' => [['5.4.4',   '',    'hostunknown',      true,  true]],
      '06' => [['5.2.1',   '550', 'filtered',        false,  true]],
      '07' => [['4.4.7',   '',    'expired',         false, false]],
      '08' => [['5.0.0',   '550', 'filtered',        false,  true]],
      '09' => [['5.0.0',   '550', 'userunknown',      true,  true]],
      '10' => [['5.1.10',  '',    'notaccept',        true,  true]],
      '11' => [['5.1.8',   '501', 'rejected',        false, false]],
      '12' => [['4.2.2',   '',    'mailboxfull',     false, false]],
    }
  end
end

