module LhostEngineTest::Public
  module ReceivingSES
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '02' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '03' => [['4.0.0',   '450', 'onhold',          false, false]],
      '04' => [['5.2.2',   '552', 'mailboxfull',     false,  true]],
      '05' => [['5.3.4',   '552', 'emailtoolarge',   false, false]],
      '06' => [['5.6.1',   '500', 'spamdetected',    false, false]],
      '07' => [['5.2.0',   '550', 'filtered',        false,  true]],
      '08' => [['5.2.3',   '552', 'emailtoolarge',   false, false]],
    }
  end
end

