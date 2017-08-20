require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'ApacheJames'
isexpected = [
  { 'n' => '01001', 'r' => /filtered/ },
  { 'n' => '01002', 'r' => /filtered/ },
  { 'n' => '01003', 'r' => /filtered/ },
  { 'n' => '01004', 'r' => /undefined/ },
  { 'n' => '01005', 'r' => /undefined/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

