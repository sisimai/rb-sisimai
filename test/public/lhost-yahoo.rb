module LhostEngineTest::Public
  module Yahoo
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '03' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '04' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '05' => [['5.2.1',   '550', 'userunknown',      true,  true]],
      '06' => [['5.0.910', '550', 'filtered',        false,  true]],
      '07' => [['5.0.911', '550', 'userunknown',      true,  true]],
      '08' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '09' => [['5.0.932', '',    'notaccept',        true,  true]],
      '10' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '11' => [['5.1.8',   '501', 'rejected',        false, false]],
      '12' => [['5.1.8',   '501', 'rejected',        false, false]],
      '13' => [['5.0.930', '',    'systemerror',     false, false]],
      '14' => [['5.0.971', '554', 'blocked',         false, false]],
    }
  end
end

