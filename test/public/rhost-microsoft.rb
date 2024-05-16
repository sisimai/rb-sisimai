module RhostEngineTest::Public
  module Microsoft
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.7.606', '550', 'blocked',         false]],
      '02' => [['5.4.1',   '550', 'userunknown',     true]],
      '03' => [['5.1.10',  '550', 'userunknown',     true]],
      '04' => [['5.7.509', '550', 'authfailure',     false]],
    }
  end
end

