require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Bigfoot'
isexpected = [
  { 'n' => '01001', 'r' => /spamdetected/ },
  { 'n' => '01002', 'r' => /userunknown/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

