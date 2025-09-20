module LhostEngineTest::Public
  module RFC3464
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce'], [...]]
      '01' => [['5.1.1',   '550', 'mailboxfull',     false]],
      '03' => [['5.0.0',   '554', 'policyviolation', false]],
      '04' => [['5.5.0',   '554', 'systemerror',     false]],
      '06' => [['5.5.0',   '554', 'userunknown',     true]],
      '07' => [['4.4.0',   '',    'expired',         false]],
      '08' => [['5.7.1',   '550', 'spamdetected',    false]],
      '09' => [['4.3.0',   '',    'mailboxfull',     false]],
      '10' => [['5.1.6',   '550', 'hasmoved',        true]],
      '26' => [['5.1.1',   '550', 'userunknown',     true]],
      '28' => [['2.1.5',   '250', 'delivered',       false],
               ['2.1.5',   '250', 'delivered',       false]],
      '29' => [['5.5.0',   '503', 'syntaxerror',     false]],
      '34' => [['4.4.1',   '',    'networkerror',    false]],
      '35' => [['5.0.0',   '550', 'rejected',        false],
               ['4.0.0',   '',    'networkerror',    false],
               ['5.0.0',   '550', 'filtered',        false]],
      '36' => [['4.0.0',   '',    'expired',         false]],
      '40' => [['4.4.6',   '',    'networkerror',    false]],
      '42' => [['5.0.0',   '',    'filtered',        false]],
      '43' => [['4.3.0',   '451', 'systemerror',     false]],
      '51' => [['5.1.0',   '550', 'userunknown',     true]],
      '52' => [['4.0.0',   '',    'notaccept',       false]],
      '53' => [['4.0.0',   '',    'networkerror',    false]],
      '54' => [['4.0.0',   '',    'networkerror',    false]],
      '55' => [['4.4.1',   '',    'expired',         false]],
      '56' => [['4.4.1',   '',    'expired',         false]],
      '57' => [['5.0.0',   '550', 'filtered',        false]],
      '58' => [['5.0.0',   '550', 'userunknown',     true]],
      '59' => [['4.0.0',   '',    'notaccept',       false]],
      '60' => [['5.1.8',   '501', 'rejected',        false]],
      '61' => [['5.0.0',   '',    'spamdetected',    false]],
      '62' => [['4.0.0',   '',    'networkerror',    false]],
      '63' => [['5.1.1',   '550', 'userunknown',     true]],
      '64' => [['4.0.0',   '',    'networkerror',    false]],
      '65' => [['5.0.0',   '',    'userunknown',     true]],
    }
  end
end

