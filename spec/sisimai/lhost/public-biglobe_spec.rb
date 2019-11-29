require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Biglobe'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]0[.]\d+\z/, 'r' => /mailboxfull/, 'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

