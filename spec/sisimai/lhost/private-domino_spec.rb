require 'spec_helper'
require './spec/sisimai/lhost/code'
enginename = 'Domino'
isexpected = [
  { 'n' => '01001', 'r' => /onhold/ },
  { 'n' => '01002', 'r' => /userunknown/ },
  { 'n' => '01003', 'r' => /userunknown/ },
  { 'n' => '01004', 'r' => /userunknown/ },
  { 'n' => '01005', 'r' => /onhold/ },
  { 'n' => '01006', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /userunknown/ },
  { 'n' => '01008', 'r' => /userunknown/ },
  { 'n' => '01009', 'r' => /userunknown/ },
  { 'n' => '01010', 'r' => /userunknown/ },
  { 'n' => '01011', 'r' => /userunknown/ },
  { 'n' => '01012', 'r' => /userunknown/ },
  { 'n' => '01013', 'r' => /userunknown/ },
  { 'n' => '01014', 'r' => /userunknown/ },
  { 'n' => '01015', 'r' => /networkerror/},
  { 'n' => '01016', 'r' => /systemerror/ },
]
Sisimai::Lhost::Code.maketest(enginename, isexpected, true)

