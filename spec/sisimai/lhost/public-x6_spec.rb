require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'X6'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]4[.]6\z/, 'r' => /networkerror/, 'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/,  'b' => /\A0\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

