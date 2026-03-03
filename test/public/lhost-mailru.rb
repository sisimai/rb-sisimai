module LhostEngineTest::Public
  module MailRu
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '03' => [['5.2.2',   '550', 'mailboxfull',     false, 1],
               ['5.2.1',   '550', 'userunknown',      true, 1]],
      '04' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '05' => [['5.9.215', '',    'notaccept',        true, 1]],
      '06' => [['5.9.212', '',    'hostunknown',      true, 1]],
      '07' => [['5.9.210', '550', 'filtered',        false, 1]],
      '08' => [['5.9.213', '550', 'userunknown',      true, 1]],
      '09' => [['5.1.8',   '501', 'rejected',        false, 0]],
      '10' => [['5.9.340', '',    'expired',         false, 0]],
    }
  end
end

