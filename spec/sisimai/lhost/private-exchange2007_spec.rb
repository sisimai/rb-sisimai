require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Exchange2007'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /mesgtoobig/ },
  { 'n' => '01003', 'r' => /userunknown/ },
  { 'n' => '01004', 'r' => /userunknown/ },
  { 'n' => '01005', 'r' => /mailboxfull/ },
  { 'n' => '01006', 'r' => /mesgtoobig/ },
  { 'n' => '01007', 'r' => /mailboxfull/ },
  { 'n' => '01008', 'r' => /securityerror/ },
  { 'n' => '01009', 'r' => /userunknown/ },
  { 'n' => '01010', 'r' => /userunknown/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

