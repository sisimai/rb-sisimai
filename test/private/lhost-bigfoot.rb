module LhostEngineTest::Private
  module Bigfoot
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01001' => [['5.0.0',   '554', 'spamdetected',    false, false]],
      '01002' => [['5.7.1',   '553', 'userunknown',      true,  true]],
    }
  end
end

