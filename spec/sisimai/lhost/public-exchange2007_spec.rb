require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Exchange2007'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]2[.]2\z/, 'r' => /mailboxfull/, 'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]2[.]3\z/, 'r' => /mesgtoobig/,  'b' => /\A1\z/ },
  { 'n' => '04', 's' => /\A5[.]7[.]1\z/, 'r' => /securityerror/,'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A4[.]4[.]1\z/, 'r' => /expired/,     'b' => /\A1\z/ },
  { 'n' => '06', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

