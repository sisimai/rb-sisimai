module LhostEngineTest::Public
  module ARF
    IsExpected = {
      # INDEX => [['D.S.N.', 'replycode', 'REASON', 'hardbounce', 'toxic'], [...]]
      '01' => [['', '', 'feedback', false,  1, 'abuse'       ]],
      '02' => [['', '', 'feedback', false,  1, 'abuse'       ]],
      '11' => [['', '', 'feedback', false,  1, 'abuse'       ]],
      '12' => [['', '', 'feedback', false,  1, 'opt-out'     ]],
      '14' => [['', '', 'feedback', false,  1, 'abuse'       ]],
      '15' => [['', '', 'feedback', false,  1, 'abuse'       ]],
      '16' => [['', '', 'feedback', false,  1, 'abuse'       ],
               ['', '', 'feedback', false,  1, 'abuse'       ],
               ['', '', 'feedback', false,  1, 'abuse'       ],
               ['', '', 'feedback', false,  1, 'abuse'       ],
               ['', '', 'feedback', false,  1, 'abuse'       ],
               ['', '', 'feedback', false,  1, 'abuse'       ],
               ['', '', 'feedback', false,  1, 'abuse'       ]],
      '17' => [['', '', 'feedback', false,  1, 'abuse'       ],
               ['', '', 'feedback', false,  1, 'abuse'       ]],
      '18' => [['', '', 'feedback', false,  0, 'auth-failure']],
      '19' => [['', '', 'feedback', false,  0, 'auth-failure']],
      '20' => [['', '', 'feedback', false,  0, 'auth-failure']],
      '21' => [['', '', 'feedback', false,  1, 'abuse'       ]],
      '22' => [['', '', 'feedback', false,  1, 'abuse'       ]],
      '23' => [['', '', 'feedback', false,  1, 'abuse'       ]],
      '24' => [['', '', 'feedback', false,  1, 'abuse'       ]],
      '25' => [['', '', 'feedback', false,  1, 'abuse'       ]],
      '26' => [['', '', 'feedback', false,  1, 'opt-out'     ]],
    }
  end
end


