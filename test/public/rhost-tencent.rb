module RhostEngineTest::Public
  module Tencent
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.0',   '550', 'ratelimited',     false, 0]],
      '02' => [['5.0.0',   '550', 'ratelimited',     false, 0]],
      '03' => [['5.0.0',   '550', 'authfailure',     false, 0]],
    }
  end
end

