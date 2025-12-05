module LhostEngineTest::Private
  module Biglobe
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.0.922', '',    'mailboxfull',     false, false]],
      '1002'  => [['5.0.922', '',    'mailboxfull',     false, false]],
      '1003'  => [['5.0.922', '',    'mailboxfull',     false, false]],
      '1004'  => [['5.0.922', '',    'mailboxfull',     false, false]],
      '1005'  => [['5.0.910', '',    'filtered',        false, false]],
      '1006'  => [['5.0.910', '',    'filtered',        false, false]],
    }
  end
end

