require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'X4'
isexpected = [
  { 'n' => '01001', 'r' => /mailboxfull/ },
  { 'n' => '01002', 'r' => /mailboxfull/ },
  { 'n' => '01003', 'r' => /hostunknown/ },
  { 'n' => '01004', 'r' => /mailboxfull/ },
  { 'n' => '01005', 'r' => /userunknown/ },
  { 'n' => '01006', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /userunknown/ },
  { 'n' => '01008', 'r' => /userunknown/ },
  { 'n' => '01009', 'r' => /userunknown/ },
  { 'n' => '01010', 'r' => /hostunknown/ },
  { 'n' => '01011', 'r' => /userunknown/ },
  { 'n' => '01012', 'r' => /mailboxfull/ },
  { 'n' => '01013', 'r' => /mailboxfull/ },
  { 'n' => '01014', 'r' => /mailboxfull/ },
  { 'n' => '01015', 'r' => /mailboxfull/ },
  { 'n' => '01016', 'r' => /mailboxfull/ },
  { 'n' => '01017', 'r' => /networkerror/ },
  { 'n' => '01018', 'r' => /userunknown/ },
  { 'n' => '01019', 'r' => /userunknown/ },
  { 'n' => '01020', 'r' => /mailboxfull/ },
  { 'n' => '01021', 'r' => /networkerror/ },
  { 'n' => '01022', 'r' => /userunknown/ },
  { 'n' => '01023', 'r' => /mailboxfull/ }
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

