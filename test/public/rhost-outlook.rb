module RhostEngineTest::Public
  module Outlook
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '02' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '03' => [['5.5.0',   '554', 'hostunknown',      true, 1]],
      '04' => [['5.1.1',   '550', 'userunknown',      true, 1],
               ['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '06' => [['4.4.7',   '',    'expired',         false, 0]],
      '07' => [['4.4.7',   '',    'expired',         false, 0]],
      '08' => [['5.5.0',   '550', 'userunknown',      true, 1]],
      '09' => [['5.5.0',   '550', 'requireptr',      false, 0]],
    }
  end
end

