require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Yahoo'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /mailboxfull/ },
  { 'n' => '01003', 'r' => /filtered/ },
  { 'n' => '01004', 'r' => /userunknown/ },
  { 'n' => '01005', 'r' => /blocked/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

