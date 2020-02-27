require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Barracuda'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]7[.]1\z/, 'r' => /spamdetected/, 'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.]7[.]1\z/, 'r' => /spamdetected/, 'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

