module RhostEngineTest::Public
  module GSuite
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      "01" => [["5.1.0",   "550", "userunknown",      true, 1]],
      "02" => [["5.0.0",   "",    "userunknown",      true, 1]],
      "03" => [["4.0.0",   "",    "notaccept",       false, 0]],
      "04" => [["4.0.0",   "",    "networkerror",    false, 0]],
      "05" => [["4.0.0",   "",    "networkerror",    false, 0]],
      "06" => [["4.4.1",   "",    "expired",         false, 0]],
      "07" => [["4.4.1",   "",    "expired",         false, 0]],
      "08" => [["5.0.0",   "550", "filtered",        false, 1]],
      "09" => [["5.0.0",   "550", "userunknown",      true, 1]],
      "10" => [["4.0.0",   "",    "notaccept",       false, 0]],
      "11" => [["5.1.8",   "501", "rejected",        false, 0]],
      "12" => [["5.0.0",   "",    "spamdetected",    false, 0]],
      "13" => [["4.0.0",   "",    "networkerror",    false, 0]],
      "14" => [["5.1.1",   "550", "userunknown",      true, 1]],
    }
  end
end

