module LhostEngineTest::Private
  module Mimecast
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '1001'  => [['5.4.1',   '',    'userunknown',      true, 1]],
      '1002'  => [['4.4.4',   '',    'networkerror',    false, 0]],
      '1003'  => [['5.1.1',   '',    'userunknown',      true, 1]],
      '1004'  => [['5.4.14',  '554', 'networkerror',    false, 0]],
      '1005'  => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '1006'  => [['5.7.54',  '550', 'norelaying',      false, 1]],
      '1007'  => [['5.7.1',   '550', 'blocked',         false, 0]],
      '1008'  => [['5.2.1',   '550', 'suspend',         false, 1]],
    }
  end
end

