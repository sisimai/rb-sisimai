require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'X3'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]3[.]0\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]0[.]\d+\z/, 'r' => /expired/,     'b' => /\A1\z/ },
  { 'n' => '03', 's' => /\A5[.]3[.]0\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '05', 's' => /\A5[.]0[.]\d+\z/, 'r' => /undefined/,   'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

