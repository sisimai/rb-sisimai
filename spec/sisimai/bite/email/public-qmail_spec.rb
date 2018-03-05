require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Qmail'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]5[.]0\z/,   'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.][12][.]1\z/,'r' => /(?:userunknown|filtered)/, 'b' => /\d\z/ },
  { 'n' => '03', 's' => /\A5[.]7[.]1\z/,   'r' => /rejected/,      'b' => /\A1\z/ },
  { 'n' => '04', 's' => /\A5[.]0[.]0\z/,   'r' => /blocked/,       'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A4[.]4[.]3\z/,   'r' => /systemerror/,   'b' => /\A1\z/ },
  { 'n' => '06', 's' => /\A4[.]2[.]2\z/,   'r' => /mailboxfull/,   'b' => /\A1\z/ },
  { 'n' => '07', 's' => /\A4[.]4[.]1\z/,   'r' => /networkerror/,  'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A5[.]0[.]\d+\z/, 'r' => /mailboxfull/,   'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

