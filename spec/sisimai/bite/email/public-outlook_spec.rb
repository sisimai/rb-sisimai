require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Outlook'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]2[.]2\z/, 'r' => /mailboxfull/,   'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A5[.]5[.]0\z/, 'r' => /hostunknown/,   'b' => /\A0\z/ },
  { 'n' => '04', 's' => /\A5[.][12][.][12]\z/, 'r' => /(?:mailboxfull|userunknown)/, 'b' => /\A[01]\z/ },
  { 'n' => '06', 's' => /\A4[.]4[.]7\z/, 'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '07', 's' => /\A4[.]4[.]7\z/, 'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '08', 's' => /\A5[.]5[.]0\z/, 'r' => /userunknown/,   'b' => /\A0\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

