require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'IMailServer'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]0[.]\d+\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]0[.]\d+\z/, 'r' => /mailboxfull/, 'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]0[.]\d+\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '04', 's' => /\A5[.]0[.]\d+\z/, 'r' => /expired/,     'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

