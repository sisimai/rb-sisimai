require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'ApacheJames'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]0[.]\d+\z/, 'r' => /filtered/, 'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

