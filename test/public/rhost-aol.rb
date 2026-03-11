module RhostEngineTest::Public
  module Aol
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.4.4',   '',    'hostunknown',      true, 1]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '03' => [['5.2.2',   '550', 'mailboxfull',     false, 1],
               ['5.1.1',   '550', 'userunknown',      true, 1]],
      '04' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '05' => [['5.4.4',   '',    'hostunknown',      true, 1]],
      '06' => [['5.4.4',   '',    'notaccept',        true, 1]],
    }
  end
end

