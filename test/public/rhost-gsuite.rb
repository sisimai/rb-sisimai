module RhostEngineTest::Public
  module GSuite
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      "01" => [["5.1.0",   "550", "userunknown",      true,  true]],
      "02" => [["5.0.0",   "",    "userunknown",      true,  true]],
      "03" => [["4.0.0",   "",    "notaccept",       false, false]],
      "04" => [["4.0.0",   "",    "networkerror",    false, false]],
      "05" => [["4.0.0",   "",    "networkerror",    false, false]],
      "06" => [["4.4.1",   "",    "expired",         false, false]],
      "07" => [["4.4.1",   "",    "expired",         false, false]],
      "08" => [["5.0.0",   "550", "filtered",        false,  true]],
      "09" => [["5.0.0",   "550", "userunknown",      true,  true]],
      "10" => [["4.0.0",   "",    "notaccept",       false, false]],
      "11" => [["5.1.8",   "501", "rejected",        false, false]],
      "12" => [["5.0.0",   "",    "spamdetected",    false, false]],
      "13" => [["4.0.0",   "",    "networkerror",    false, false]],
      "14" => [["5.1.1",   "550", "userunknown",      true,  true]],
    }
  end
end

