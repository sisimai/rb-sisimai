module LhostEngineTest::Public
  module RFC3834
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['',        '', 'vacation', false, false]],
      '02' => [['',        '', 'vacation', false, false]],
      '03' => [['',        '', 'vacation', false, false]],
      '04' => [['',        '', 'vacation', false, false]],
      '05' => [['',        '', 'vacation', false, false]],
      '06' => [['5.9.221', '', 'suspend',  false,  true]],
    }
  end
end

