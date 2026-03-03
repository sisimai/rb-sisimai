module LhostEngineTest::Private
  module DragonFly
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001' => [['5.7.26',  '550', 'authfailure',     false, 0]],
      '1002' => [['5.9.340', '',    'expired',         false, 0]],
    }
  end
end

