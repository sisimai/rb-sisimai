module LhostEngineTest::Private
  module EinsUndEins
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.0.922', '',    'mailboxfull',     false]],
      '01002' => [['5.0.922', '',    'mailboxfull',     false]],
      '01003' => [['5.0.934', '',    'mesgtoobig',      false]],
      '01004' => [['5.1.1',   '550', 'userunknown',     true]],
      '01005' => [['5.4.1',   '550', 'userunknown',     true]],
      '01006' => [['5.4.1',   '550', 'userunknown',     true]],
      '01007' => [['5.4.1',   '550', 'userunknown',     true]],
      '01008' => [['5.4.1',   '550', 'userunknown',     true]],
      '01009' => [['5.1.1',   '550', 'userunknown',     true]],
      '01010' => [['5.1.1',   '550', 'userunknown',     true]],
      '01011' => [['5.4.1',   '550', 'userunknown',     true]],
      '01012' => [['5.4.1',   '550', 'userunknown',     true]],
      '01013' => [['5.4.1',   '550', 'userunknown',     true]],

    }
  end
end

