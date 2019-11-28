require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'MailMarshalSMTP'
isexpected = [
  { 'n' => '01001', 'r' => /filtered/ },
  { 'n' => '01002', 'r' => /userunknown/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

