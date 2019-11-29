require 'spec_helper'
require './spec/obsoleted/sisimai/bite/json/code'
enginename = 'AmazonSES'
isexpected = [
  { 'n' => '01', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
  { 'n' => '03', 's' => /\A\z/,          'r' => /feedback/,    'b' => /\A-1\z/ },
  { 'n' => '04', 's' => /\A2[.]6[.]0\z/, 'r' => /delivered/,   'b' => /\A-1\z/ },
  { 'n' => '05', 's' => /\A2[.]6[.]0\z/, 'r' => /delivered/,   'b' => /\A-1\z/ },
  { 'n' => '06', 's' => /\A5[.]1[.]1\z/, 'r' => /userunknown/, 'b' => /\A0\z/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected)

