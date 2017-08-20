require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Yandex'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.][12][.][12]\z/, 'r' => /(?:userunknown|mailboxfull)/, 'b' => /\d\z/ },
  { 'n' => '03', 's' => /\A4[.]4[.]1\z/, 'r' => /expired/,     'b' => /\A1\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

