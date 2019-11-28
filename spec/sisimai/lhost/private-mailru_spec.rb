require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'MailRu'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /userunknown/ },
  { 'n' => '01003', 'r' => /mailboxfull/ },
  { 'n' => '01004', 'r' => /(?:mailboxfull|userunknown)/ },
  { 'n' => '01005', 'r' => /filtered/ },
  { 'n' => '01006', 'r' => /mailboxfull/ },
  { 'n' => '01007', 'r' => /userunknown/ },
  { 'n' => '01008', 'r' => /userunknown/ },
  { 'n' => '01009', 'r' => /filtered/ },
  { 'n' => '01010', 'r' => /userunknown/ },
  { 'n' => '01011', 'r' => /rejected/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

