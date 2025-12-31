module LhostEngineTest::Public
  module Exchange2007
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '03' => [['5.2.3',   '550', 'emailtoolarge',   false, false]],
      '04' => [['5.7.1',   '550', 'securityerror',   false, false]],
      '05' => [['4.4.1',   '',    'expired',         false, false]],
      '06' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '07' => [['5.1.1',   '550', 'userunknown',      true,  true]],
    }
  end
end

