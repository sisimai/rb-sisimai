module LhostEngineTest::Public
  module Office365
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.10',  '550', 'userunknown',      true, 1]],
      '02' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '03' => [['5.1.0',   '550', 'authfailure',     false, 0]],
      '04' => [['5.1.351', '550', 'filtered',        false, 1]],
      '05' => [['5.1.8',   '501', 'rejected',        false, 0]],
      '06' => [['5.4.312', '550', 'networkerror',    false, 0]],
      '07' => [['5.1.351', '550', 'userunknown',      true, 1]],
      '08' => [['5.4.316', '550', 'networkerror',    false, 0]],
      '09' => [['5.1.351', '550', 'userunknown',      true, 1]],
      '10' => [['5.1.351', '550', 'userunknown',      true, 1]],
      '11' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '12' => [['5.2.2',   '550', 'mailboxfull',     false, 1]],
      '13' => [['5.1.10',  '550', 'userunknown',      true, 1]],
    }
  end
end

