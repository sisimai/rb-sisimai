module LhostEngineTest::Public
  module RFC3464
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['5.1.1',   '550', 'mailboxfull',     false, 1]],
      '03' => [['5.0.0',   '554', 'policyviolation', false, 0]],
      '04' => [['5.5.0',   '554', 'systemerror',     false, 0]],
      '06' => [['5.5.0',   '554', 'userunknown',      true, 1]],
      '07' => [['4.4.0',   '',    'expired',         false, 0]],
      '08' => [['5.7.1',   '550', 'spamdetected',    false, 0]],
      '09' => [['4.3.0',   '',    'mailboxfull',     false, 0]],
      '10' => [['5.1.6',   '550', 'hasmoved',         true, 1]],
      '26' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '28' => [['2.1.5',   '250', 'delivered',       false, 0],
               ['2.1.5',   '250', 'delivered',       false, 0]],
      '29' => [['5.5.0',   '503', 'syntaxerror',     false, 0]],
      '34' => [['4.4.1',   '',    'networkerror',    false, 0]],
      '35' => [['5.0.0',   '550', 'rejected',        false, 0],
               ['4.0.0',   '',    'networkerror',    false, 0],
               ['5.0.0',   '550', 'filtered',        false, 1]],
      '36' => [['4.0.0',   '',    'expired',         false, 0]],
      '40' => [['4.4.6',   '',    'networkerror',    false, 0]],
      '42' => [['5.0.0',   '',    'filtered',        false, 1]],
      '43' => [['4.3.0',   '451', 'systemerror',     false, 0]],
      '51' => [['5.1.0',   '550', 'userunknown',      true, 1]],
      '52' => [['4.0.0',   '',    'notaccept',       false, 0]],
      '53' => [['4.0.0',   '',    'networkerror',    false, 0]],
      '54' => [['4.0.0',   '',    'networkerror',    false, 0]],
      '55' => [['4.4.1',   '',    'expired',         false, 0]],
      '56' => [['4.4.1',   '',    'expired',         false, 0]],
      '57' => [['5.0.0',   '550', 'filtered',        false, 1]],
      '58' => [['5.0.0',   '550', 'userunknown',      true, 1]],
      '59' => [['4.0.0',   '',    'notaccept',       false, 0]],
      '60' => [['5.1.8',   '501', 'rejected',        false, 0]],
      '61' => [['5.0.0',   '',    'spamdetected',    false, 0]],
      '62' => [['4.0.0',   '',    'networkerror',    false, 0]],
      '63' => [['5.1.1',   '550', 'userunknown',      true, 1]],
      '64' => [['4.0.0',   '',    'networkerror',    false, 0]],
      '65' => [['5.0.0',   '',    'userunknown',      true, 1]],
      '66' => [['5.0.0',   '',    'filtered',        false, 1]],
    }
  end
end

