require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'GMX'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]2[.]2\z/,   'r' => /mailboxfull/, 'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A5[.][12][.][12]\z/, 'r' => /(?:userunknown|mailboxfull)/, 'b' => /\d\z/ },
  { 'n' => '04', 's' => /\A5[.]0[.]\d+\z/, 'r' => /expired/,     'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

