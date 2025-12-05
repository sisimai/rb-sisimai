module LhostEngineTest::Private
  module DragonFly
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001' => [['5.7.26',  '550', 'authfailure',     false, false]],
      '1002' => [['5.0.947', '',    'expired',         false, false]],
    }
  end
end

