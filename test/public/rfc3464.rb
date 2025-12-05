module LhostEngineTest::Public
  module RFC3464
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'mailboxfull',     false,  true]],
      '03' => [['5.0.0',   '554', 'policyviolation', false, false]],
      '04' => [['5.5.0',   '554', 'systemerror',     false, false]],
      '06' => [['5.5.0',   '554', 'userunknown',      true,  true]],
      '07' => [['4.4.0',   '',    'expired',         false, false]],
      '08' => [['5.7.1',   '550', 'spamdetected',    false, false]],
      '09' => [['4.3.0',   '',    'mailboxfull',     false, false]],
      '10' => [['5.1.6',   '550', 'hasmoved',         true,  true]],
      '26' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '28' => [['2.1.5',   '250', 'delivered',       false, false],
               ['2.1.5',   '250', 'delivered',       false, false]],
      '29' => [['5.5.0',   '503', 'syntaxerror',     false, false]],
      '34' => [['4.4.1',   '',    'networkerror',    false, false]],
      '35' => [['5.0.0',   '550', 'rejected',        false, false],
               ['4.0.0',   '',    'networkerror',    false, false],
               ['5.0.0',   '550', 'filtered',        false,  true]],
      '36' => [['4.0.0',   '',    'expired',         false, false]],
      '40' => [['4.4.6',   '',    'networkerror',    false, false]],
      '42' => [['5.0.0',   '',    'filtered',        false,  true]],
      '43' => [['4.3.0',   '451', 'systemerror',     false, false]],
      '51' => [['5.1.0',   '550', 'userunknown',      true,  true]],
      '52' => [['4.0.0',   '',    'notaccept',       false, false]],
      '53' => [['4.0.0',   '',    'networkerror',    false, false]],
      '54' => [['4.0.0',   '',    'networkerror',    false, false]],
      '55' => [['4.4.1',   '',    'expired',         false, false]],
      '56' => [['4.4.1',   '',    'expired',         false, false]],
      '57' => [['5.0.0',   '550', 'filtered',        false,  true]],
      '58' => [['5.0.0',   '550', 'userunknown',      true,  true]],
      '59' => [['4.0.0',   '',    'notaccept',       false, false]],
      '60' => [['5.1.8',   '501', 'rejected',        false, false]],
      '61' => [['5.0.0',   '',    'spamdetected',    false, false]],
      '62' => [['4.0.0',   '',    'networkerror',    false, false]],
      '63' => [['5.1.1',   '550', 'userunknown',      true,  true]],
      '64' => [['4.0.0',   '',    'networkerror',    false, false]],
      '65' => [['5.0.0',   '',    'userunknown',      true,  true]],
      '66' => [['5.0.0',   '',    'filtered',        false,  true]],
    }
  end
end

