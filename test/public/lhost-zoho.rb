module LhostEngineTest::Public
  module Zoho
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.2.1',   '550', 'filtered',        false, 1],
               ['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '03' => [['5.9.210', '550', 'filtered',        false, 1]],
      '04' => [['4.9.340', '421', 'expired',         false, 0]],
      '05' => [['4.9.340', '421', 'expired',         false, 0]],
    }
  end
end

