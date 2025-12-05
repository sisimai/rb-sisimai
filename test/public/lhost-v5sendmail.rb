module LhostEngineTest::Public
  module V5sendmail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['4.0.947', '421', 'expired',         false, false]],
      '02' => [['5.0.912', '550', 'hostunknown',      true,  true]],
      '03' => [['5.0.911', '550', 'userunknown',      true,  true]],
      '04' => [['5.0.912', '550', 'hostunknown',      true,  true],
               ['5.0.912', '550', 'hostunknown',      true,  true]],
      '05' => [['5.0.971', '550', 'blocked',         false, false],
               ['5.0.912', '550', 'hostunknown',      true,  true],
               ['5.0.912', '550', 'hostunknown',      true,  true],
               ['5.0.911', '550', 'userunknown',      true,  true]],
      '06' => [['5.0.909', '550', 'norelaying',      false,  true]],
      '07' => [['5.0.971', '554', 'blocked',         false, false],
               ['5.0.912', '550', 'hostunknown',      true,  true],
               ['5.0.911', '550', 'userunknown',      true,  true]],
    }
  end
end

