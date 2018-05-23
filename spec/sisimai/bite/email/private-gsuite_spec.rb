require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'GSuite'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /userunknown/ },
  { 'n' => '01003', 'r' => /blocked/ },
  { 'n' => '01004', 'r' => /filtered/ },
  { 'n' => '01005', 'r' => /userunknown/ },
  { 'n' => '01006', 'r' => /notaccept/ },
  { 'n' => '01007', 'r' => /rejected/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

