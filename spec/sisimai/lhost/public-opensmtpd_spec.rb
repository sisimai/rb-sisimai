require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'OpenSMTPD'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/,       'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.][12][.][12]\z/, 'r' => /(?:userunknown|mailboxfull)/, 'b' => /\d\z/ },
  { 'n' => '03', 's' => /\A5[.]0[.]\d+\z/,     'r' => /hostunknown/,   'b' => /\A0\z/ },
  { 'n' => '04', 's' => /\A5[.]0[.]\d+\z/,     'r' => /networkerror/,  'b' => /\A1\z/ },
  { 'n' => '05', 's' => /\A5[.]0[.]\d+\z/,     'r' => /expired/,       'b' => /\A1\z/ },
  { 'n' => '06', 's' => /\A5[.]0[.]\d+\z/,     'r' => /expired/,       'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

