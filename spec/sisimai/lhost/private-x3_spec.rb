require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'X3'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /undefined/ },
  { 'n' => '01003', 'r' => /expired/ },
  { 'n' => '01004', 'r' => /userunknown/ },
  { 'n' => '01005', 'r' => /undefined/ },
  { 'n' => '01006', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /expired/ },
  { 'n' => '01008', 'r' => /userunknown/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

