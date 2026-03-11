module LhostEngineTest::Public
  module V5sendmail
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['4.9.340', '421', 'expired',         false, 0]],
      '02' => [['5.9.212', '550', 'hostunknown',      true, 1]],
      '03' => [['5.9.213', '550', 'userunknown',      true, 1]],
      '04' => [['5.9.212', '550', 'hostunknown',      true, 1],
               ['5.9.212', '550', 'hostunknown',      true, 1]],
      '05' => [['5.9.231', '550', 'systemerror',      false, 0],
               ['5.9.212', '550', 'hostunknown',      true, 1],
               ['5.9.212', '550', 'hostunknown',      true, 1],
               ['5.9.213', '550', 'userunknown',      true, 1]],
      '06' => [['5.9.214', '550', 'norelaying',      false, 1]],
      '07' => [['5.9.134', '554', 'blocked',         false, 0],
               ['5.9.212', '550', 'hostunknown',      true, 1],
               ['5.9.213', '550', 'userunknown',      true, 1]],
    }
  end
end

