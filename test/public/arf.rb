module LhostEngineTest::Public
  module ARF
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['', '', 'feedback', false,  true, 'abuse'       ]],
      '02' => [['', '', 'feedback', false,  true, 'abuse'       ]],
      '11' => [['', '', 'feedback', false,  true, 'abuse'       ]],
      '12' => [['', '', 'feedback', false,  true, 'opt-out'     ]],
      '14' => [['', '', 'feedback', false,  true, 'abuse'       ]],
      '15' => [['', '', 'feedback', false,  true, 'abuse'       ]],
      '16' => [['', '', 'feedback', false,  true, 'abuse'       ],
               ['', '', 'feedback', false,  true, 'abuse'       ],
               ['', '', 'feedback', false,  true, 'abuse'       ],
               ['', '', 'feedback', false,  true, 'abuse'       ],
               ['', '', 'feedback', false,  true, 'abuse'       ],
               ['', '', 'feedback', false,  true, 'abuse'       ],
               ['', '', 'feedback', false,  true, 'abuse'       ]],
      '17' => [['', '', 'feedback', false,  true, 'abuse'       ],
               ['', '', 'feedback', false,  true, 'abuse'       ]],
      '18' => [['', '', 'feedback', false, false, 'auth-failure']],
      '19' => [['', '', 'feedback', false, false, 'auth-failure']],
      '20' => [['', '', 'feedback', false, false, 'auth-failure']],
      '21' => [['', '', 'feedback', false,  true, 'abuse'       ]],
      '22' => [['', '', 'feedback', false,  true, 'abuse'       ]],
      '23' => [['', '', 'feedback', false,  true, 'abuse'       ]],
      '24' => [['', '', 'feedback', false,  true, 'abuse'       ]],
      '25' => [['', '', 'feedback', false,  true, 'abuse'       ]],
      '26' => [['', '', 'feedback', false,  true, 'opt-out'     ]],
    }
  end
end


