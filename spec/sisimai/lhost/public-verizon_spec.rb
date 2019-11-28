require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Verizon'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]0[.]\d+\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

