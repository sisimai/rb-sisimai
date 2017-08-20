require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Notes'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]0[.]\d+\z/, 'r' => /onhold/,        'b' => /\d\z/ },
  { 'n' => '02', 's' => /\A5[.]0[.]\d+\z/, 'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A5[.]0[.]\d+\z/, 'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '04', 's' => /\A5[.]0[.]\d+\z/, 'r' => /networkerror/,  'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

