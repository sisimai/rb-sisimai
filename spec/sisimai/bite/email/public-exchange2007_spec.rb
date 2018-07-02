require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Exchange2007'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]2[.]2\z/, 'r' => /mailboxfull/, 'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]2[.]3\z/, 'r' => /mesgtoobig/,  'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

