require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'GMX'
isexpected = [
  { 'n' => '01001', 'r' => /expired/ },
  { 'n' => '01002', 'r' => /userunknown/ },
  { 'n' => '01003', 'r' => /mailboxfull/ },
  { 'n' => '01004', 'r' => /(?:userunknown|mailboxfull)/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

