require 'spec_helper'
require './spec/sisimai/bite/email/code'
enginename = 'Exim'
isexpected = [
  { 'n' => '01001', 'r' => /policyviolation/ },
  { 'n' => '01002', 'r' => /expired/ },
  { 'n' => '01003', 'r' => /filtered/ },
  { 'n' => '01004', 'r' => /blocked/ },
  { 'n' => '01005', 'r' => /userunknown/ },
  { 'n' => '01006', 'r' => /filtered/ },
  { 'n' => '01007', 'r' => /policyviolation/ },
  { 'n' => '01008', 'r' => /userunknown/ },
  { 'n' => '01009', 'r' => /hostunknown/ },
  { 'n' => '01010', 'r' => /blocked/ },
  { 'n' => '01011', 'r' => /userunknown/ },
  { 'n' => '01012', 'r' => /userunknown/ },
  { 'n' => '01013', 'r' => /userunknown/ },
  { 'n' => '01014', 'r' => /expired/ },
  { 'n' => '01015', 'r' => /expired/ },
  { 'n' => '01016', 'r' => /userunknown/ },
  { 'n' => '01017', 'r' => /expired/ },
  { 'n' => '01018', 'r' => /userunknown/ },
  { 'n' => '01019', 'r' => /userunknown/ },
  { 'n' => '01020', 'r' => /userunknown/ },
  { 'n' => '01022', 'r' => /userunknown/ },
  { 'n' => '01023', 'r' => /userunknown/ },
  { 'n' => '01024', 'r' => /userunknown/ },
  { 'n' => '01025', 'r' => /userunknown/ },
  { 'n' => '01026', 'r' => /userunknown/ },
  { 'n' => '01027', 'r' => /expired/ },
  { 'n' => '01028', 'r' => /mailboxfull/ },
  { 'n' => '01029', 'r' => /userunknown/ },
  { 'n' => '01031', 'r' => /expired/ },
  { 'n' => '01032', 'r' => /userunknown/ },
  { 'n' => '01033', 'r' => /userunknown/ },
  { 'n' => '01034', 'r' => /userunknown/ },
  { 'n' => '01035', 'r' => /rejected/ },
  { 'n' => '01036', 'r' => /userunknown/ },
  { 'n' => '01037', 'r' => /expired/ },
  { 'n' => '01038', 'r' => /blocked/ },
  { 'n' => '01039', 'r' => /mailboxfull/ },
  { 'n' => '01040', 'r' => /expired/ },
  { 'n' => '01041', 'r' => /expired/ },
  { 'n' => '01042', 'r' => /networkerror/ },
  { 'n' => '01043', 'r' => /userunknown/ },
  { 'n' => '01044', 'r' => /networkerror/ },
  { 'n' => '01045', 'r' => /hostunknown/ },
  { 'n' => '01046', 'r' => /userunknown/ },
  { 'n' => '01047', 'r' => /userunknown/ },
  { 'n' => '01049', 'r' => /suspend/ },
  { 'n' => '01050', 'r' => /userunknown/ },
  { 'n' => '01051', 'r' => /userunknown/ },
  { 'n' => '01053', 'r' => /userunknown/ },
  { 'n' => '01054', 'r' => /suspend/ },
  { 'n' => '01055', 'r' => /userunknown/ },
  { 'n' => '01056', 'r' => /userunknown/ },
  { 'n' => '01057', 'r' => /suspend/ },
  { 'n' => '01058', 'r' => /userunknown/ },
  { 'n' => '01059', 'r' => /onhold/ },
  { 'n' => '01060', 'r' => /expired/ },
  { 'n' => '01061', 'r' => /userunknown/ },
  { 'n' => '01062', 'r' => /userunknown/ },
  { 'n' => '01063', 'r' => /userunknown/ },
  { 'n' => '01064', 'r' => /userunknown/ },
  { 'n' => '01065', 'r' => /userunknown/ },
  { 'n' => '01066', 'r' => /userunknown/ },
  { 'n' => '01067', 'r' => /userunknown/ },
  { 'n' => '01068', 'r' => /userunknown/ },
  { 'n' => '01069', 'r' => /userunknown/ },
  { 'n' => '01070', 'r' => /userunknown/ },
  { 'n' => '01071', 'r' => /userunknown/ },
  { 'n' => '01072', 'r' => /userunknown/ },
  { 'n' => '01073', 'r' => /suspend/ },
  { 'n' => '01074', 'r' => /userunknown/ },
  { 'n' => '01075', 'r' => /userunknown/ },
  { 'n' => '01076', 'r' => /userunknown/ },
  { 'n' => '01077', 'r' => /suspend/ },
  { 'n' => '01078', 'r' => /undefined/ },
  { 'n' => '01079', 'r' => /hostunknown/ },
  { 'n' => '01080', 'r' => /hostunknown/ },
  { 'n' => '01081', 'r' => /hostunknown/ },
  { 'n' => '01082', 'r' => /onhold/ },
  { 'n' => '01083', 'r' => /onhold/ },
  { 'n' => '01084', 'r' => /systemerror/ },
  { 'n' => '01085', 'r' => /(?:undefined|onhold|blocked)/ },
  { 'n' => '01086', 'r' => /onhold/ },
  { 'n' => '01087', 'r' => /onhold/ },
  { 'n' => '01088', 'r' => /(?:systemerror|onhold)/ },
  { 'n' => '01089', 'r' => /mailererror/ },
  { 'n' => '01090', 'r' => /onhold/ },
  { 'n' => '01091', 'r' => /onhold/ },
  { 'n' => '01092', 'r' => /undefined/ },
  { 'n' => '01093', 'r' => /(?:undefined|onhold|systemerror)/ },
  { 'n' => '01094', 'r' => /onhold/ },
  { 'n' => '01095', 'r' => /undefined/ },
  { 'n' => '01096', 'r' => /(?:hostunknown|onhold)/ },
  { 'n' => '01097', 'r' => /(?:hostunknown|networkerror)/ },
  { 'n' => '01098', 'r' => /expired/ },
  { 'n' => '01099', 'r' => /expired/ },
  { 'n' => '01100', 'r' => /mailererror/ },
  { 'n' => '01101', 'r' => /mailererror/ },
  { 'n' => '01102', 'r' => /mailererror/ },
  { 'n' => '01103', 'r' => /undefined/ },
  { 'n' => '01104', 'r' => /mailererror/ },
  { 'n' => '01105', 'r' => /mailererror/ },
  { 'n' => '01106', 'r' => /onhold/ },
  { 'n' => '01107', 'r' => /spamdetected/ },
  { 'n' => '01108', 'r' => /policyviolation/ },
  { 'n' => '01109', 'r' => /userunknown/ },
  { 'n' => '01110', 'r' => /hostunknown/ },
  { 'n' => '01111', 'r' => /blocked/ },
  { 'n' => '01112', 'r' => /blocked/ },
  { 'n' => '01113', 'r' => /blocked/ },
  { 'n' => '01114', 'r' => /blocked/ },
  { 'n' => '01115', 'r' => /rejected/ },
  { 'n' => '01116', 'r' => /filtered/ },
  { 'n' => '01117', 'r' => /blocked/ },
  { 'n' => '01118', 'r' => /blocked/ },
  { 'n' => '01119', 'r' => /blocked/ },
  { 'n' => '01120', 'r' => /blocked/ },
  { 'n' => '01121', 'r' => /blocked/ },
  { 'n' => '01122', 'r' => /rejected/ },
  { 'n' => '01123', 'r' => /mailererror/ },
  { 'n' => '01124', 'r' => /rejected/ },
  { 'n' => '01125', 'r' => /blocked/ },
  { 'n' => '01126', 'r' => /blocked/ },
  { 'n' => '01127', 'r' => /rejected/ },
  { 'n' => '01128', 'r' => /blocked/ },
  { 'n' => '01129', 'r' => /rejected/ },
  { 'n' => '01130', 'r' => /rejected/ },
  { 'n' => '01131', 'r' => /syntaxerror/ },
  { 'n' => '01132', 'r' => /mailererror/ },
  { 'n' => '01133', 'r' => /blocked/ },
  { 'n' => '01134', 'r' => /spamdetected/ },
  { 'n' => '01135', 'r' => /blocked/ },
  { 'n' => '01136', 'r' => /rejected/ },
  { 'n' => '01137', 'r' => /userunknown/ },
  { 'n' => '01138', 'r' => /blocked/ },
  { 'n' => '01139', 'r' => /rejected/ },
  { 'n' => '01140', 'r' => /toomanyconn/ },
  { 'n' => '01141', 'r' => /filtered/ },
  { 'n' => '01142', 'r' => /virusdetected/ },
  { 'n' => '01143', 'r' => /userunknown/ },
  { 'n' => '01144', 'r' => /(?:blocked|onhold)/ },
  { 'n' => '01145', 'r' => /mesgtoobig/ },
  { 'n' => '01146', 'r' => /userunknown/ },
  { 'n' => '01147', 'r' => /blocked/ },
  { 'n' => '01148', 'r' => /spamdetected/ },
  { 'n' => '01149', 'r' => /rejected/ },
  { 'n' => '01150', 'r' => /blocked/ },
  { 'n' => '01151', 'r' => /suspend/ },
  { 'n' => '01152', 'r' => /blocked/ },
  { 'n' => '01153', 'r' => /blocked/ },
  { 'n' => '01154', 'r' => /blocked/ },
  { 'n' => '01155', 'r' => /blocked/ },
  { 'n' => '01156', 'r' => /blocked/ },
  { 'n' => '01157', 'r' => /spamdetected/ },
  { 'n' => '01158', 'r' => /filtered/ },
  { 'n' => '01159', 'r' => /spamdetected/ },
  { 'n' => '01160', 'r' => /(?:blocked|userunknown|onhold)/ },
  { 'n' => '01161', 'r' => /mesgtoobig/ },
  { 'n' => '01162', 'r' => /blocked/ },
]
Sisimai::Bite::Email::Code.maketest(enginename, isexpected, true)

