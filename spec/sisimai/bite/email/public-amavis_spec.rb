require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Amavis'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '02', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected)

