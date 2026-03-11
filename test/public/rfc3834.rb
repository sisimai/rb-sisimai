module LhostEngineTest::Public
  module RFC3834
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['',        '', 'vacation', false, 0]],
      '02' => [['',        '', 'vacation', false, 0]],
      '03' => [['',        '', 'vacation', false, 0]],
      '04' => [['',        '', 'vacation', false, 0]],
      '05' => [['',        '', 'vacation', false, 0]],
      '06' => [['5.9.221', '', 'suspend',  false, 1]],
    }
  end
end

