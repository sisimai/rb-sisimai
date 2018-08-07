require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Office365'
isexpected = [
  { 'n' => '01001', 'r' => /filtered/ },
  { 'n' => '01002', 'r' => /filtered/ },
  { 'n' => '01003', 'r' => /filtered/ },
  { 'n' => '01004', 'r' => /filtered/ },
  { 'n' => '01005', 'r' => /filtered/ },
  { 'n' => '01006', 'r' => /networkerror/ },
  { 'n' => '01007', 'r' => /userunknown/ },
  { 'n' => '01008', 'r' => /userunknown/ },
  { 'n' => '01009', 'r' => /securityerror/ },
  { 'n' => '01010', 'r' => /blocked/ },
  { 'n' => '01011', 'r' => /filtered/ },
  { 'n' => '01012', 'r' => /rejected/ },
  { 'n' => '01013', 'r' => /networkerror/ },
  { 'n' => '01014', 'r' => /userunknown/ },
  { 'n' => '01015', 'r' => /userunknown/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

