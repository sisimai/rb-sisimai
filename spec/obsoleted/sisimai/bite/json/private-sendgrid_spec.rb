require 'spec_helper'
require './spec/obsoleted/sisimai/bite/json/code'
enginename = 'SendGrid'
isexpected = [
  { 'n' => '01001', 'r' => /(?:userunknown|filtered|mailboxfull)/ },
  { 'n' => '01002', 'r' => /(?:mailboxfull|filtered)/ },
  { 'n' => '01003', 'r' => /userunknown/ },
  { 'n' => '01004', 'r' => /filtered/ },
  { 'n' => '01005', 'r' => /filtered/ },
  { 'n' => '01006', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /filtered/ },
  { 'n' => '01008', 'r' => /userunknown/ },
  { 'n' => '01009', 'r' => /userunknown/ },
  { 'n' => '01010', 'r' => /userunknown/ },
  { 'n' => '01011', 'r' => /hostunknown/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

