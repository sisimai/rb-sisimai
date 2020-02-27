require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'X6'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /userunknown/ },
  { 'n' => '01003', 'r' => /userunknown/ },
  { 'n' => '01004', 'r' => /userunknown/ },
  { 'n' => '01005', 'r' => /userunknown/ },
  { 'n' => '01006', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /userunknown/ },
  { 'n' => '01008', 'r' => /userunknown/ },
  { 'n' => '01009', 'r' => /userunknown/ },
  { 'n' => '01010', 'r' => /userunknown/ },
  { 'n' => '01011', 'r' => /userunknown/ },
  { 'n' => '01012', 'r' => /userunknown/ },
  { 'n' => '01013', 'r' => /userunknown/ },
  { 'n' => '01014', 'r' => /userunknown/ },
  { 'n' => '01015', 'r' => /userunknown/ },
  { 'n' => '01016', 'r' => /userunknown/ },
  { 'n' => '01017', 'r' => /userunknown/ },
  { 'n' => '01018', 'r' => /userunknown/ },
  { 'n' => '01019', 'r' => /userunknown/ },
  { 'n' => '01020', 'r' => /userunknown/ },
  { 'n' => '01021', 'r' => /networkerror/ },
  { 'n' => '01022', 'r' => /userunknown/ },
  { 'n' => '01023', 'r' => /userunknown/ },
  { 'n' => '01024', 'r' => /networkerror/ },
  { 'n' => '01025', 'r' => /norelaying/ },
  { 'n' => '01026', 'r' => /userunknown/ },
  { 'n' => '01027', 'r' => /securityerror/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

