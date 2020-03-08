require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Office365'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /userunknown/ },
  { 'n' => '01003', 'r' => /userunknown/ },
  { 'n' => '01004', 'r' => /userunknown/ },
  { 'n' => '01005', 'r' => /userunknown/ },
  { 'n' => '01006', 'r' => /networkerror/ },
  { 'n' => '01007', 'r' => /userunknown/ },
  { 'n' => '01008', 'r' => /userunknown/ },
  { 'n' => '01009', 'r' => /securityerror/ },
  { 'n' => '01010', 'r' => /blocked/ },
  { 'n' => '01011', 'r' => /filtered/ },
  { 'n' => '01012', 'r' => /rejected/ },
  { 'n' => '01013', 'r' => /networkerror/ },
  { 'n' => '01014', 'r' => /userunknown/ },
  { 'n' => '01015', 'r' => /userunknown/ },
  { 'n' => '01016', 'r' => /userunknown/ },
  { 'n' => '01017', 'r' => /mailboxfull/ },
  { 'n' => '01018', 'r' => /userunknown/ },
  { 'n' => '01019', 'r' => /userunknown/ },
  { 'n' => '01020', 'r' => /userunknown/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

