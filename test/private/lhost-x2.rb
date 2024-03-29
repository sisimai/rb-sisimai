module LhostEngineTest::Private
  module X2
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01001' => [['5.7.1',   '554', 'norelaying',      false]],
      '01002' => [['5.0.910', '',    'filtered',        false]],
      '01003' => [['5.0.910', '',    'filtered',        false]],
      '01004' => [['5.0.910', '',    'filtered',        false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.910', '',    'filtered',        false]],
      '01005' => [['5.0.947', '',    'expired',         false]],
      '01006' => [['5.1.2',   '',    'hostunknown',     true]],
      '01007' => [['5.0.947', '',    'expired',         false]],
      '01008' => [['4.4.1',   '',    'expired',         false]],
      '01009' => [['5.0.922', '',    'mailboxfull',     false]],
      '01010' => [['5.0.921', '',    'suspend',         false]],
      '01011' => [['5.0.922', '',    'mailboxfull',     false],
                  ['5.0.922', '',    'mailboxfull',     false]],
      '01012' => [['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false]],
      '01013' => [['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false]],
      '01014' => [['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false]],
      '01015' => [['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false]],
      '01016' => [['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false]],
      '01017' => [['5.0.910', '',    'filtered',        false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.910', '',    'filtered',        false]],
      '01018' => [['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false]],
      '01019' => [['5.0.922', '',    'mailboxfull',     false]],
      '01020' => [['5.0.910', '',    'filtered',        false]],
      '01021' => [['5.0.910', '',    'filtered',        false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.910', '',    'filtered',        false]],
      '01022' => [['5.0.910', '',    'filtered',        false]],
      '01023' => [['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false]],
      '01024' => [['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false]],
      '01025' => [['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false]],
      '01026' => [['5.0.921', '',    'suspend',         false],
                  ['5.0.921', '',    'suspend',         false]],
      '01027' => [['5.0.922', '',    'mailboxfull',     false],
                  ['5.0.922', '',    'mailboxfull',     false]],
      '01028' => [['4.4.1',   '',    'expired',         false]],
      '01029' => [['4.1.9',   '',    'expired',         false]],
    }
  end
end

