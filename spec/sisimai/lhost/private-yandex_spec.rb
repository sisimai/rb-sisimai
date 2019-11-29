require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Yandex'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /(?:userunknown|mailboxfull)/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

