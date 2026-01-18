module LhostEngineTest::Private
  module Biglobe
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.220', '',    'mailboxfull',     false, false]],
      '1002'  => [['5.9.220', '',    'mailboxfull',     false, false]],
      '1003'  => [['5.9.220', '',    'mailboxfull',     false, false]],
      '1004'  => [['5.9.220', '',    'mailboxfull',     false, false]],
      '1005'  => [['5.9.210', '',    'filtered',        false, false]],
      '1006'  => [['5.9.210', '',    'filtered',        false, false]],
    }
  end
end

