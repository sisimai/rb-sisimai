require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'FML'
isexpected = [
  { 'n' => '02', 's' => /\A5[.]0[.]\d+\z/, 'r' => /rejected/,    'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]0[.]\d+\z/, 'r' => /systemerror/, 'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

