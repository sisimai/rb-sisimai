module RhostEngineTest::Public
  module Aol
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.4.4',   '',    'hostunknown',      true,  true]],
      '02' => [['5.2.2',   '550', 'mailboxfull',     false,  true]],
      '03' => [['5.2.2',   '550', 'mailboxfull',     false,  true],
               ['5.1.1',   '550', 'userunknown',      true,  true]],
      '04' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '05' => [['5.4.4',   '',    'hostunknown',      true,  true]],
      '06' => [['5.4.4',   '',    'notaccept',        true,  true]],
    }
  end
end

