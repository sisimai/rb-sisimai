require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'KDDI'
isexpected = [
  { 'n' => '01001', 'r' => /mailboxfull/ },
  { 'n' => '01002', 'r' => /mailboxfull/ },
  { 'n' => '01003', 'r' => /mailboxfull/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

