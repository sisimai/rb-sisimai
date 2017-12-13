require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Office365'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]10\z/, 'r' => /filtered/,     'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.]1[.]1\z/,  'r' => /userunknown/,  'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A5[.]1[.]0\z/,  'r' => /blocked/,      'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

