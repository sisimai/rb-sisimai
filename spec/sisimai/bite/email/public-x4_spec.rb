require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'X4'
isexpected = [
  { 'n' => '08', 's' => /\A4[.]4[.]1\z/,   'r' => /networkerror/,  'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

