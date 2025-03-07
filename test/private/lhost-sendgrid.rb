module LhostEngineTest::Private
  module SendGrid
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '1001'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1002'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1003'  => [['5.0.947', '',    'expired',         false]],
      '1004'  => [['5.0.911', '550', 'userunknown',     true]],
      '1005'  => [['5.2.1',   '550', 'userunknown',     true]],
      '1006'  => [['5.2.2',   '550', 'mailboxfull',     false]],
      '1007'  => [['5.1.1',   '550', 'userunknown',     true]],
      '1008'  => [['5.0.911', '554', 'userunknown',     true]],
      '1009'  => [['5.0.911', '550', 'userunknown',     true]],
    }
  end
end

