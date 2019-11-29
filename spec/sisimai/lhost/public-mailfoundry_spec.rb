require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'MailFoundry'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]0[.]\d+\z/, 'r' => /filtered/,   'b' => /\A1\z/ },
  { 'n' => '02', 's' => /\A5[.]1[.]1\z/,   'r' => /mailboxfull/,'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

