module RhostEngineTest::Public
  module Microsoft
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.7.606', '550', 'blocked',         false, 0]],
      '02' => [['5.4.1',   '550', 'userunknown',      true, 1]],
      '03' => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '04' => [['5.7.509', '550', 'authfailure',     false, 0]],
      '05' => [['4.7.650', '451', 'badreputation',   false, 0]],
      '06' => [['5.7.515', '550', 'authfailure',     false, 0]],
    }
  end
end

