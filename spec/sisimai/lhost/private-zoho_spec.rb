require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Zoho'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /(?:filtered|mailboxfull)/ },
  { 'n' => '01003', 'r' => /filtered/ },
  { 'n' => '01004', 'r' => /expired/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

