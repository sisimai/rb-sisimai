require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Aol'
isexpected = [
  { 'n' => '01001', 'r' => /hostunknown/ },
  { 'n' => '01002', 'r' => /mailboxfull/ },
  { 'n' => '01003', 'r' => /(?:mailboxfull|userunknown)/ },
  { 'n' => '01004', 'r' => /(?:mailboxfull|userunknown)/ },
  { 'n' => '01005', 'r' => /userunknown/ },
  { 'n' => '01006', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /mailboxfull/ },
  { 'n' => '01008', 'r' => /filtered/ },
  { 'n' => '01009', 'r' => /policyviolation/ },
  { 'n' => '01010', 'r' => /filtered/ },
  { 'n' => '01011', 'r' => /filtered/ },
  { 'n' => '01012', 'r' => /mailboxfull/ },
  { 'n' => '01013', 'r' => /mailboxfull/ },
  { 'n' => '01014', 'r' => /userunknown/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

