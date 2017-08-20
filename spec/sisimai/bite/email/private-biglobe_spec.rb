require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Biglobe'
isexpected = [
  { 'n' => '01001', 'r' => /mailboxfull/ },
  { 'n' => '01002', 'r' => /mailboxfull/ },
  { 'n' => '01003', 'r' => /mailboxfull/ },
  { 'n' => '01004', 'r' => /mailboxfull/ },
  { 'n' => '01005', 'r' => /filtered/ },
  { 'n' => '01006', 'r' => /filtered/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

