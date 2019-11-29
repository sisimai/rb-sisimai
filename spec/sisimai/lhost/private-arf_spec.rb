require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'ARF'
isexpected = [
  { 'n' => '01001', 'r' => /feedback/ },
  { 'n' => '01002', 'r' => /feedback/ },
  { 'n' => '01003', 'r' => /feedback/ },
  { 'n' => '01004', 'r' => /feedback/ },
  { 'n' => '01005', 'r' => /feedback/ },
  { 'n' => '01006', 'r' => /feedback/ },
  { 'n' => '01007', 'r' => /feedback/ },
  { 'n' => '01008', 'r' => /feedback/ },
  { 'n' => '01009', 'r' => /feedback/ },
  { 'n' => '01010', 'r' => /feedback/ },
  { 'n' => '01011', 'r' => /feedback/ },
  { 'n' => '01012', 'r' => /feedback/ },
  { 'n' => '01013', 'r' => /feedback/ },
  { 'n' => '01014', 'r' => /feedback/ },
  { 'n' => '01015', 'r' => /feedback/ },
  { 'n' => '01016', 'r' => /feedback/ },
  { 'n' => '01017', 'r' => /feedback/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

