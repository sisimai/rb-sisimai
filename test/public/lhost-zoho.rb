module LhostEngineTest::Public
  module Zoho
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.2.1',   '550', 'filtered',        false,  true],
               ['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '03' => [['5.0.910', '550', 'filtered',        false,  true]],
      '04' => [['4.0.947', '421', 'expired',         false, false]],
      '05' => [['4.0.947', '421', 'expired',         false, false]],
    }
  end
end

