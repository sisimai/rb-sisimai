require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Barracuda'
isexpected = [
  { 'n' => '01001', 'r' => /spamdetected/ },
  { 'n' => '01002', 'r' => /spamdetected/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

