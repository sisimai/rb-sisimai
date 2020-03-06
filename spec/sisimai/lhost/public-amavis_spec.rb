require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Amavis'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A5[.]7[.]0\z/, 'r' => /spamdetected/,'b' => /\A1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

