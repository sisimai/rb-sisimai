require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Yahoo'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /mailboxfull/ },
  { 'n' => '01003', 'r' => /userunknown/ },
  { 'n' => '01004', 'r' => /userunknown/ },
  { 'n' => '01005', 'r' => /blocked/ },
  { 'n' => '01006', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /mailboxfull/ },
  { 'n' => '01008', 'r' => /notaccept/ },
  { 'n' => '01009', 'r' => /userunknown/ },
  { 'n' => '01010', 'r' => /rejected/ },
  { 'n' => '01011', 'r' => /blocked/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

