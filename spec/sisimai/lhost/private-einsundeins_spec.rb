require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'EinsUndEins'
isexpected = [
  { 'n' => '01001', 'r' => /undefined/ },
  { 'n' => '01002', 'r' => /undefined/ },
  { 'n' => '01003', 'r' => /mesgtoobig/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

