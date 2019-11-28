require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'MFILTER'
isexpected = [
  { 'n' => '01001', 'r' => /filtered/ },
  { 'n' => '01002', 'r' => /userunknown/ },
  { 'n' => '01003', 'r' => /filtered/ },
  { 'n' => '01004', 'r' => /filtered/ },
  { 'n' => '01005', 'r' => /userunknown/ },
  { 'n' => '01006', 'r' => /filtered/ },
  { 'n' => '01007', 'r' => /filtered/ },
  { 'n' => '01008', 'r' => /rejected/ },
  { 'n' => '01009', 'r' => /rejected/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

