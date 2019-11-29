require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'ApacheJames'
isexpected = [
  { 'n' => '01001', 'r' => /filtered/ },
  { 'n' => '01002', 'r' => /filtered/ },
  { 'n' => '01003', 'r' => /filtered/ },
  { 'n' => '01004', 'r' => /onhold/ },
  { 'n' => '01005', 'r' => /onhold/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

