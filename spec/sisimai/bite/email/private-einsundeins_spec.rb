require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'EinsUndEins'
isexpected = [
  { 'n' => '01001', 'r' => /undefined/ },
  { 'n' => '01002', 'r' => /undefined/ },
  { 'n' => '01003', 'r' => /mesgtoobig/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

