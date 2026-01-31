module LhostEngineTest::Public
  module V5sendmail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['4.9.340', '421', 'expired',         false, false]],
      '02' => [['5.9.212', '550', 'hostunknown',      true,  true]],
      '03' => [['5.9.213', '550', 'userunknown',      true,  true]],
      '04' => [['5.9.212', '550', 'hostunknown',      true,  true],
               ['5.9.212', '550', 'hostunknown',      true,  true]],
      '05' => [['5.9.231', '550', 'systemerror',      false, false],
               ['5.9.212', '550', 'hostunknown',      true,  true],
               ['5.9.212', '550', 'hostunknown',      true,  true],
               ['5.9.213', '550', 'userunknown',      true,  true]],
      '06' => [['5.9.214', '550', 'norelaying',      false,  true]],
      '07' => [['5.9.134', '554', 'blocked',         false, false],
               ['5.9.212', '550', 'hostunknown',      true,  true],
               ['5.9.213', '550', 'userunknown',      true,  true]],
    }
  end
end

