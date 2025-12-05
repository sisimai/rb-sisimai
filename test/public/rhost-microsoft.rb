module RhostEngineTest::Public
  module Microsoft
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.7.606', '550', 'blocked',         false, false]],
      '02' => [['5.4.1',   '550', 'userunknown',      true,  true]],
      '03' => [['5.1.10',  '550', 'userunknown',      true,  true]],
      '04' => [['5.7.509', '550', 'authfailure',     false, false]],
      '05' => [['4.7.650', '451', 'badreputation',   false, false]],
      '06' => [['5.7.515', '550', 'authfailure',     false, false]],
    }
  end
end

