require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'GSuite'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /userunknown/ },
  { 'n' => '01003', 'r' => /spamdetected/ },
  { 'n' => '01004', 'r' => /filtered/ },
  { 'n' => '01005', 'r' => /userunknown/ },
  { 'n' => '01006', 'r' => /notaccept/ },
  { 'n' => '01007', 'r' => /rejected/ },
  { 'n' => '01008', 'r' => /networkerror/ },
  { 'n' => '01009', 'r' => /userunknown/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

