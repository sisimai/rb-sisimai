require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'SendGrid'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]1[.]1\z/,   'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A5[.]0[.]\d+\z/, 'r' => /expired/,     'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

