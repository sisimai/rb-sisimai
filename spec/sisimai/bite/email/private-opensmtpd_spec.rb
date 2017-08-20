require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'OpenSMTPD'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /filtered/ },
  { 'n' => '01003', 'r' => /mailboxfull/ },
  { 'n' => '01004', 'r' => /filtered/ },
  { 'n' => '01005', 'r' => /filtered/ },
  { 'n' => '01006', 'r' => /expired/ },
  { 'n' => '01007', 'r' => /userunknown/ },
  { 'n' => '01008', 'r' => /(?:mailboxfull|userunknown)/ },
  { 'n' => '01009', 'r' => /hostunknown/ },
  { 'n' => '01010', 'r' => /networkerror/ },
  { 'n' => '01011', 'r' => /userunknown/ },
  { 'n' => '01012', 'r' => /(?:mailboxfull|userunknown)/ },
  { 'n' => '01013', 'r' => /hostunknown/ },
  { 'n' => '01014', 'r' => /expired/ },
  { 'n' => '01015', 'r' => /networkerror/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

