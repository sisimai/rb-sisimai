require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Outlook'
isexpected = [
  { 'n' => '01002', 'r' => /userunknown/ },
  { 'n' => '01003', 'r' => /userunknown/ },
  { 'n' => '01007', 'r' => /blocked/ },
  { 'n' => '01008', 'r' => /mailboxfull/ },
  { 'n' => '01016', 'r' => /mailboxfull/ },
  { 'n' => '01017', 'r' => /userunknown/ },
  { 'n' => '01018', 'r' => /hostunknown/ },
  { 'n' => '01019', 'r' => /(?:userunknown|mailboxfull)/ },
  { 'n' => '01023', 'r' => /userunknown/ },
  { 'n' => '01024', 'r' => /userunknown/ },
  { 'n' => '01025', 'r' => /filtered/ },
  { 'n' => '01026', 'r' => /filtered/ },
  { 'n' => '01027', 'r' => /userunknown/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

