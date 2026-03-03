module LhostEngineTest::Public
  module ReceivingSES
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '02' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '03' => [['4.0.0',   '450', 'onhold',          false, 0]],
      '04' => [['5.2.2',   '552', 'mailboxfull',     false, 1]],
      '05' => [['5.3.4',   '552', 'emailtoolarge',   false, 0]],
      '06' => [['5.6.1',   '500', 'spamdetected',    false, 0]],
      '07' => [['5.2.0',   '550', 'filtered',        false, 1]],
      '08' => [['5.2.3',   '552', 'emailtoolarge',   false, 0]],
    }
  end
end

