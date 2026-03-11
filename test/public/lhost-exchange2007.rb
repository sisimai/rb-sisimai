module LhostEngineTest::Public
  module Exchange2007
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '03' => [['5.2.3',   '550', 'emailtoolarge',   false, 0]],
      '04' => [['5.7.1',   '550', 'securityerror',   false, 0]],
      '05' => [['4.4.1',   '',    'expired',         false, 0]],
      '06' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '07' => [['5.1.1',   '550', 'userunknown',      true, 1]],
    }
  end
end

