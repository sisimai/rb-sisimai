module LhostEngineTest::Private
  module Biglobe
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1002'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1003'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1004'  => [['5.9.220', '',    'mailboxfull',     false, 0]],
      '1005'  => [['5.9.210', '',    'filtered',        false, 0]],
      '1006'  => [['5.9.210', '',    'filtered',        false, 0]],
    }
  end
end

