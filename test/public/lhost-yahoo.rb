module LhostEngineTest::Public
  module Yahoo
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '03' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '04' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '05' => [['5.2.1',   '550', 'userunknown',      true,  true]],
      '06' => [['5.9.210', '550', 'filtered',        false,  true]],
      '07' => [['5.9.213', '550', 'userunknown',      true,  true]],
      '08' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '09' => [['5.9.215', '',    'notaccept',        true,  true]],
      '10' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '11' => [['5.1.8',   '501', 'rejected',        false, false]],
      '12' => [['5.1.8',   '501', 'rejected',        false, false]],
      '13' => [['5.9.340', '',    'expired',         false, false]],
      '14' => [['5.9.134', '554', 'blocked',         false, false]],
    }
  end
end

