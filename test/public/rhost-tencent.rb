module RhostEngineTest::Public
  module Tencent
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.0.0',   '550', 'toomanyconn',     false, false]],
      '02' => [['5.0.0',   '550', 'toomanyconn',     false, false]],
      '03' => [['5.0.0',   '550', 'authfailure',     false, false]],
    }
  end
end

