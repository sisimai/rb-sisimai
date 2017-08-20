require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'MailFoundry'
isexpected = [
  { 'n' => '01001', 'r' => /filtered/ },
  { 'n' => '01002', 'r' => /mailboxfull/ },
  { 'n' => '01003', 'r' => /userunknown/ },
  { 'n' => '01004', 'r' => /filtered/ },
  { 'n' => '01005', 'r' => /mailboxfull/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

