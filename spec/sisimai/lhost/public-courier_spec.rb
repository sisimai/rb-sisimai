require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Courier'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/,   'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]0[.]0\z/, 'r' => /filtered/,      'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]7[.]1\z/, 'r' => /blocked/,       'b' => /\A1\z/ },
  { 'n' => '04', 's' => /\A5[.]0[.]0\z/, 'r' => /hostunknown/,   'b' => /\A0\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)
