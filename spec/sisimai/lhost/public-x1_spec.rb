require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'X1'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]0[.]\d+\z/, 'r' => /filtered/, 'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.]0[.]\d+\z/, 'r' => /filtered/, 'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

