require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'ReceivingSES'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/, 'r' => /filtered/,    'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.]1[.]1\z/, 'r' => /filtered/,    'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A4[.]0[.]0\z/, 'r' => /onhold/,      'b' => /\d\z/ },
  { 'n' => '04', 's' => /\A5[.]2[.]2\z/, 'r' => /mailboxfull/, 'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A5[.]3[.]4\z/, 'r' => /mesgtoobig/,  'b' => /\A1\z/ },
  { 'n' => '06', 's' => /\A5[.]6[.]1\z/, 'r' => /contenterror/,'b' => /\A1\z/ },
  { 'n' => '07', 's' => /\A5[.]2[.]0\z/, 'r' => /filtered/,    'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

