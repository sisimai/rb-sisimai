require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'MessageLabs'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /securityerror/ },
  { 'n' => '01003', 'r' => /userunknown/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

