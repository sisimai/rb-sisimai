require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'X2'
isexpected = [
  { 'n' => '01001', 'r' => /norelaying/ },
  { 'n' => '01002', 'r' => /filtered/ },
  { 'n' => '01003', 'r' => /filtered/ },
  { 'n' => '01004', 'r' => /(?:suspend|filtered)/ },
  { 'n' => '01005', 'r' => /expired/ },
  { 'n' => '01006', 'r' => /hostunknown/ },
  { 'n' => '01007', 'r' => /expired/ },
  { 'n' => '01008', 'r' => /expired/ },
  { 'n' => '01009', 'r' => /mailboxfull/ },
  { 'n' => '01010', 'r' => /suspend/ },
  { 'n' => '01011', 'r' => /mailboxfull/ },
  { 'n' => '01012', 'r' => /suspend/ },
  { 'n' => '01013', 'r' => /suspend/ },
  { 'n' => '01014', 'r' => /suspend/ },
  { 'n' => '01015', 'r' => /suspend/ },
  { 'n' => '01016', 'r' => /suspend/ },
  { 'n' => '01017', 'r' => /(?:suspend|filtered)/ },
  { 'n' => '01018', 'r' => /suspend/ },
  { 'n' => '01019', 'r' => /mailboxfull/ },
  { 'n' => '01020', 'r' => /filtered/ },
  { 'n' => '01021', 'r' => /(?:filtered|suspend)/ },
  { 'n' => '01022', 'r' => /filtered/ },
  { 'n' => '01023', 'r' => /suspend/ },
  { 'n' => '01024', 'r' => /suspend/ },
  { 'n' => '01025', 'r' => /suspend/ },
  { 'n' => '01026', 'r' => /suspend/ },
  { 'n' => '01027', 'r' => /mailboxfull/ },
  { 'n' => '01028', 'r' => /expired/ },
  { 'n' => '01029', 'r' => /expired/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

