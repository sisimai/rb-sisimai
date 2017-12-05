require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'RFC3834'
isexpected = [
  { 'n' => '01002', 'r' => /vacation/ },
  { 'n' => '01003', 'r' => /vacation/ },
  { 'n' => '01004', 'r' => /vacation/ },
  { 'n' => '01005', 'r' => /vacation/ },
  { 'n' => '01006', 'r' => /vacation/ },
  { 'n' => '01007', 'r' => /vacation/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

