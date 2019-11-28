require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'FML'
isexpected = [
  { 'n' => '01001', 'r' => /systemerror/ },
  { 'n' => '01002', 'r' => /rejected/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

