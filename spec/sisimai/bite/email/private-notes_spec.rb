require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Notes'
isexpected = [
  { 'n' => '01001', 'r' => /userunknown/ },
  { 'n' => '01002', 'r' => /onhold/ },
  { 'n' => '01003', 'r' => /onhold/ },
  { 'n' => '01004', 'r' => /userunknown/ },
  { 'n' => '01005', 'r' => /onhold/ },
  { 'n' => '01006', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /userunknown/ },
  { 'n' => '01008', 'r' => /userunknown/ },
  { 'n' => '01009', 'r' => /userunknown/ }
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

