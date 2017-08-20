require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'X1'
isexpected = [
  { 'n' => '01001', 'r' => /filtered/ },
  { 'n' => '01002', 'r' => /filtered/ },
  { 'n' => '01003', 'r' => /filtered/ },
  { 'n' => '01004', 'r' => /filtered/ },
  { 'n' => '01005', 'r' => /filtered/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

