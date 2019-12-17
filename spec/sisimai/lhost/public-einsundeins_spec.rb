require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'EinsUndEins'
isexpected = [
  { 'n' => '02', 's' => /\A5[.]0[.]\d+\z/, 'r' => /mesgtoobig/, 'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]2[.]0\z/,   'r' => /spamdetected/, 'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

