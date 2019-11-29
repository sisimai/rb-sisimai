require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Bigfoot'
isexpected = [
  { 'n' => '02', 's' => /\A5[.]7[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

