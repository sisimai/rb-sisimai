require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'FML'
isexpected = [
  { 'n' => '01001', 'r' => /systemerror/ },
  { 'n' => '01002', 'r' => /rejected/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

