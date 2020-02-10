require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'RFC3834'
isexpected = [
  { 'n' => '01', 's' => /\A\z/, 'r' => /vacation/, 'b' => /\A-1\z/ },
  { 'n' => '02', 's' => /\A\z/, 'r' => /vacation/, 'b' => /\A-1\z/ },
  { 'n' => '03', 's' => /\A\z/, 'r' => /vacation/, 'b' => /\A-1\z/ },
  { 'n' => '04', 's' => /\A\z/, 'r' => /vacation/, 'b' => /\A-1\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

