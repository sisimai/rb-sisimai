require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'EinsUndEins'
isexpected = [
  { 'n' => '02', 's' => /\A5[.]0[.]\d+\z/, 'r' => /mesgtoobig/, 'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

