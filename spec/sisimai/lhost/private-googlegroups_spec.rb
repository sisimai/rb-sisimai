require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'GoogleGroups'
isexpected = [
  { 'n' => '01001', 'r' => /rejected/ },
  { 'n' => '01002', 'r' => /rejected/ },
  { 'n' => '01003', 'r' => /rejected/ },
  { 'n' => '01004', 'r' => /rejected/ },
  { 'n' => '01005', 'r' => /rejected/ },
  { 'n' => '01006', 'r' => /rejected/ },
  { 'n' => '01007', 'r' => /rejected/ },
  { 'n' => '01008', 'r' => /rejected/ },
  { 'n' => '01009', 'r' => /rejected/ },
  { 'n' => '01010', 'r' => /rejected/ },
  { 'n' => '01010', 'r' => /rejected/ },
  { 'n' => '01011', 'r' => /rejected/ },
  { 'n' => '01012', 'r' => /rejected/ },
  { 'n' => '01013', 'r' => /rejected/ },
  { 'n' => '01014', 'r' => /rejected/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

