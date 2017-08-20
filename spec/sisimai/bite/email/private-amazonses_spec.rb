require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'AmazonSES'
isexpected = [
  { 'n' => '01001', 'r' => /mailboxfull/ },
  { 'n' => '01002', 'r' => /filtered/ },
  { 'n' => '01003', 'r' => /userunknown/ },
  { 'n' => '01004', 'r' => /mailboxfull/ },
  { 'n' => '01005', 'r' => /securityerror/ },
  { 'n' => '01006', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /expired/ },
  { 'n' => '01008', 'r' => /hostunknown/ },
  { 'n' => '01009', 'r' => /userunknown/ },
  { 'n' => '01010', 'r' => /userunknown/ },
  { 'n' => '01011', 'r' => /userunknown/ },
  { 'n' => '01012', 'r' => /userunknown/ },
  { 'n' => '01013', 'r' => /userunknown/ },
  { 'n' => '01014', 'r' => /filtered/ },
  { 'n' => '01015', 'r' => /userunknown/ },
  { 'n' => '01016', 'r' => /feedback/ },
  { 'n' => '01017', 'r' => /delivered/ },
  { 'n' => '01018', 'r' => /delivered/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

