require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Courier'
isexpected = [
  { 'n' => '01001', 'r' => /rejected/ },
  { 'n' => '01002', 'r' => /rejected/ },
  { 'n' => '01003', 'r' => /blocked/ },
  { 'n' => '01004', 'r' => /userunknown/ },
  { 'n' => '01005', 'r' => /userunknown/ },
  { 'n' => '01006', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /userunknown/ },
  { 'n' => '01008', 'r' => /userunknown/ },
  { 'n' => '01009', 'r' => /filtered/ },
  { 'n' => '01010', 'r' => /blocked/ },
  { 'n' => '01011', 'r' => /hostunknown/ },
  { 'n' => '01012', 'r' => /hostunknown/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

