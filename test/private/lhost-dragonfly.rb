module LhostEngineTest::Private
  module DragonFly
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.7.26',  '550', 'authfailure',     false]],
      '01002' => [['5.0.947', '',    'expired',         false]],
    }
  end
end

