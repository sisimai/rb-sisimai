require 'spec_helper'
require 'sisimai/data'
require 'sisimai/mail'
require 'sisimai/message'

describe 'Sisimai::MTA::*' do
  debugOnlyTo = ''
  MTAChildren = {
    'Activehunter' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
    },
    'ApacheJames' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
    },
    'Courier' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/,   'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]0[.]0\z/, 'r' => %r/filtered/,      'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]7[.]1\z/, 'r' => %r/blocked/,       'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A5[.]0[.]0\z/, 'r' => %r/hostunknown/,   'b' => %r/\A0\z/ },
    },
    'Domino' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/(?:userunknown|onhold)/, 'b' => %r/\d\z/ },
    },
    'Exchange2003' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '04' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '06' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
    },
    'Exchange2007' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]2[.]3\z/, 'r' => %r/mesgtoobig/,  'b' => %r/\A1\z/ },
    },
    'Exim' => {
      '01' => { 's' => %r/\A5[.]7[.]0\z/,   'r' => %r/blocked/,     'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.][12][.]1\z/,'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A5[.]7[.]0\z/,   'r' => %r/securityerror/,'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A5[.]7[.]0\z/,   'r' => %r/blocked/,     'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '06' => { 's' => %r/\A4[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '07' => { 's' => %r/\A4[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '08' => { 's' => %r/\A4[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '09' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
      '10' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/suspend/,     'b' => %r/\A1\z/ },
      '11' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/onhold/,      'b' => %r/\d\z/ },
      '12' => { 's' => %r/\A[45][.]0[.]\d+\z/, 'r' => %r/(?:hostunknown|expired|undefined)/, 'b' => %r/\d\z/ },
      '13' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/(?:onhold|undefined|mailererror)/, 'b' => %r/\d\z/ },
      '14' => { 's' => %r/\A4[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '15' => { 's' => %r/\A5[.]4[.]3\z/,   'r' => %r/systemerror/, 'b' => %r/\A1\z/ },
      '16' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/systemerror/, 'b' => %r/\A1\z/ },
      '17' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '18' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
      '19' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/networkerror/,'b' => %r/\A1\z/ },
      '20' => { 's' => %r/\A4[.]0[.]\d+\z/, 'r' => %r/(?:expired|systemerror)/, 'b' => %r/\A1\z/ },
      '21' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '23' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '24' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '25' => { 's' => %r/\A4[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '26' => { 's' => %r/\A5[.]0[.]0\z/,   'r' => %r/mailererror/, 'b' => %r/\A1\z/ },
      '27' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/blocked/,     'b' => %r/\A1\z/ },
      '28' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailererror/, 'b' => %r/\A1\z/ },
      '29' => { 's' => %r/\A5[.]0[.]0\z/,   'r' => %r/blocked/,     'b' => %r/\A1\z/ },
    },
    'IMailServer' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '04' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/undefined/,   'b' => %r/\d\z/ },
    },
    'InterScanMSS' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
    },
    'MailFoundry' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,   'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/mailboxfull/,'b' => %r/\A1\z/ },
    },
    'MailMarshalSMTP' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
    },
    'McAfee' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
    },
    'MXLogic' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
    },
    'MessagingServer' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]2[.]0\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]7[.]1\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A5[.]2[.]2\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A5[.]4[.]4\z/, 'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
      '06' => { 's' => %r/\A5[.]2[.]1\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '07' => { 's' => %r/\A4[.]4[.]7\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
    },
    'MFILTER' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
    },
    'Notes' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/onhold/,      'b' => %r/\d\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '04' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/networkerror/,'b' => %r/\A1\z/ },
    },
    'OpenSMTPD' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.][12][.][12]\z/, 'r' => %r/(?:userunknown|mailboxfull)/, 'b' => %r/\d\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
      '04' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/networkerror/,'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
    },
    'Postfix' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/mailererror/, 'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.][12][.]1\z/,'r' => %r/(?:filtered|userunknown)/, 'b' => %r/\d\z/ },
      '03' => { 's' => %r/\A5[.]0[.]0\z/,   'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '05' => { 's' => %r/\A4[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '06' => { 's' => %r/\A5[.]4[.]4\z/,   'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
      '07' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '08' => { 's' => %r/\A4[.]4[.]1\z/,   'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '09' => { 's' => %r/\A4[.]3[.]2\z/,   'r' => %r/toomanyconn/, 'b' => %r/\A1\z/ },
      '10' => { 's' => %r/\A5[.]1[.]8\z/,   'r' => %r/rejected/,    'b' => %r/\A1\z/ },
      '11' => { 's' => %r/\A5[.]1[.]8\z/,   'r' => %r/rejected/,    'b' => %r/\A1\z/ },
      '12' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '13' => { 's' => %r/\A5[.]2[.][12]\z/,'r' => %r/(?:userunknown|mailboxfull)/, 'b' => %r/\d\z/ },
      '14' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '15' => { 's' => %r/\A4[.]4[.]1\z/,   'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '16' => { 's' => %r/\A5[.]1[.]6\z/,   'r' => %r/hasmoved/,    'b' => %r/\A0\z/ },
      '17' => { 's' => %r/\A5[.]4[.]4\z/,   'r' => %r/networkerror/,'b' => %r/\A1\z/ },
      '18' => { 's' => %r/\A5[.]7[.]1\z/,   'r' => %r/norelaying/,  'b' => %r/\A1\z/ },
      '19' => { 's' => %r/\A5[.]0[.]0\z/,   'r' => %r/blocked/,     'b' => %r/\A1\z/ },
      '20' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/onhold/,      'b' => %r/\d\z/ },
      '21' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/networkerror/,'b' => %r/\A1\z/ },
    },
    'Qmail' => {
      '01' => { 's' => %r/\A5[.]5[.]0\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.][12][.]1\z/,'r' => %r/(?:userunknown|filtered)/, 'b' => %r/\d\z/ },
      '03' => { 's' => %r/\A5[.]7[.]1\z/,   'r' => %r/rejected/,    'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A5[.]0[.]0\z/,   'r' => %r/blocked/,     'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A4[.]4[.]3\z/,   'r' => %r/systemerror/, 'b' => %r/\A1\z/ },
      '06' => { 's' => %r/\A4[.]2[.]2\z/,   'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '07' => { 's' => %r/\A4[.]4[.]1\z/,   'r' => %r/networkerror/,'b' => %r/\A1\z/ },
      '08' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '09' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/undefined/,   'b' => %r/\d\z/ },
    },
    'Sendmail' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.][12][.]1\z/, 'r' => %r/(?:userunknown|filtered)/, 'b' => %r/\d\z/ },
      '03' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '04' => { 's' => %r/\A5[.]1[.]8\z/, 'r' => %r/rejected/,    'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A5[.]2[.]3\z/, 'r' => %r/exceedlimit/, 'b' => %r/\A1\z/ },
      '06' => { 's' => %r/\A5[.]6[.]9\z/, 'r' => %r/contenterror/,'b' => %r/\A1\z/ },
      '07' => { 's' => %r/\A5[.]7[.]1\z/, 'r' => %r/norelaying/,  'b' => %r/\A1\z/ },
      '08' => { 's' => %r/\A4[.]7[.]1\z/, 'r' => %r/blocked/,     'b' => %r/\A1\z/ },
      '09' => { 's' => %r/\A5[.]7[.]9\z/, 'r' => %r/securityerror/,'b' => %r/\A1\z/ },
      '10' => { 's' => %r/\A4[.]7[.]1\z/, 'r' => %r/blocked/,     'b' => %r/\A1\z/ },
      '11' => { 's' => %r/\A4[.]4[.]7\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '12' => { 's' => %r/\A4[.]4[.]7\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '13' => { 's' => %r/\A5[.]3[.]0\z/, 'r' => %r/systemerror/, 'b' => %r/\A1\z/ },
      '14' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '15' => { 's' => %r/\A5[.]1[.]2\z/, 'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
      '16' => { 's' => %r/\A5[.]5[.]0\z/, 'r' => %r/blocked/,     'b' => %r/\A1\z/ },
      '17' => { 's' => %r/\A5[.]1[.]6\z/, 'r' => %r/hasmoved/,    'b' => %r/\A0\z/ },
      '18' => { 's' => %r/\A5[.]0[.]0\z/, 'r' => %r/mailererror/, 'b' => %r/\A1\z/ },
      '19' => { 's' => %r/\A5[.]2[.]0\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '20' => { 's' => %r/\A5[.]4[.]6\z/, 'r' => %r/networkerror/,'b' => %r/\A1\z/ },
      '21' => { 's' => %r/\A4[.]4[.]7\z/, 'r' => %r/blocked/,     'b' => %r/\A1\z/ },
      '22' => { 's' => %r/\A5[.]1[.]6\z/, 'r' => %r/hasmoved/,    'b' => %r/\A0\z/ },
      '23' => { 's' => %r/\A5[.]7[.]1\z/, 'r' => %r/spamdetected/,'b' => %r/\A1\z/ },
      '24' => { 's' => %r/\A5[.]1[.]2\z/, 'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
      '25' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '26' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '27' => { 's' => %r/\A5[.]0[.]0\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '28' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '29' => { 's' => %r/\A4[.]5[.]0\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '30' => { 's' => %r/\A4[.]4[.]7\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '31' => { 's' => %r/\A5[.]7[.]0\z/, 'r' => %r/securityerror/, 'b' => %r/\A1\z/ },
      '32' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '33' => { 's' => %r/\A5[.]7[.]1\z/, 'r' => %r/blocked/,     'b' => %r/\A1\z/ },
      '34' => { 's' => %r/\A5[.]7[.]0\z/, 'r' => %r/securityerror/, 'b' => %r/\A1\z/ },
      '35' => { 's' => %r/\A5[.]7[.]13\z/,'r' => %r/suspend/,     'b' => %r/\A1\z/ },
      '36' => { 's' => %r/\A5[.]7[.]1\z/, 'r' => %r/blocked/,     'b' => %r/\A1\z/ },
      '37' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '38' => { 's' => %r/\A5[.]7[.]1\z/, 'r' => %r/spamdetected/,'b' => %r/\A1\z/ },
      '39' => { 's' => %r/\A4[.]4[.]5\z/, 'r' => %r/systemfull/,  'b' => %r/\A1\z/ },
    },
    'SurfControl' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/systemerror/, 'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/systemerror/, 'b' => %r/\A1\z/ },
    },
    'V5sendmail' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '04' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/hostunknown/, 'b' => %r/\A0\z/ },
      '05' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/(?:hostunknown|blocked|userunknown)/, 'b' => %r/\d\z/ },
      '06' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/norelaying/,  'b' => %r/\A1\z/ },
      '07' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/(?:hostunknown|blocked|userunknown)/, 'b' => %r/\d\z/ },
    },
    'X1' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/, 'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/, 'b' => %r/\A1\z/ },
    },
    'X2' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/filtered/,    'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/(?:filtered|suspend)/, 'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '04' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '05' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/suspend/,     'b' => %r/\A1\z/ },
    },
    'X3' => {
      '01' => { 's' => %r/\A5[.]3[.]0\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/expired/,     'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]3[.]0\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '04' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/undefined/,   'b' => %r/\d\z/ },
    },
    'X4' => {
      '01' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '02' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '03' => { 's' => %r/\A5[.]1[.]1\z/,   'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '04' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '05' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
      '06' => { 's' => %r/\A5[.]0[.]\d+\z/, 'r' => %r/mailboxfull/, 'b' => %r/\A1\z/ },
      '07' => { 's' => %r/\A4[.]4[.]1\z/,   'r' => %r/networkerror/,'b' => %r/\A1\z/ },
    },
    'X5' => {
      '01' => { 's' => %r/\A5[.]1[.]1\z/, 'r' => %r/userunknown/, 'b' => %r/\A0\z/ },
    }
  }

  MTAChildren.each_key do |x|
    cn = Module.const_get('Sisimai::MTA::' + x)

    describe cn do
      describe '.description' do
        it 'returns String' do
          expect(cn.description).to be_a String
          expect(cn.description.size).to be > 0
        end
      end
      describe '.pattern' do
        it 'returns Hash' do
          expect(cn.pattern).to be_a Hash
          expect(cn.pattern.keys.size).to be > 0
        end
      end
      describe '.scan' do
        it 'returns nil' do
          expect(cn.scan(nil,nil)).to be nil
        end
      end

      (1 .. MTAChildren[x].keys.size).each do |i|
        if debugOnlyTo.size > 0
          next unless debugOnlyTo == sprintf( "%s-%02d", x.downcase, i)
        end

        emailfn = sprintf('./set-of-emails/maildir/bsd/%s-%02d.eml', x.downcase, i)
        mailbox = Sisimai::Mail.new(emailfn)
        mailtxt = nil

        n = sprintf('%02d', i)
        next unless mailbox.path
        next unless MTAChildren[x][n]

        example sprintf('[%s] %s/mail = %s', n, cn, emailfn) do
          expect(File.exist?(emailfn)).to be true
        end

        while r = mailbox.read do
          mailtxt = r
          it 'returns String' do
            expect(mailtxt).to be_a String
          end
          p = Sisimai::Message.new(data: r, delivered: true)

          it 'returns Sisimai::Message object' do
            expect(p).to be_a Sisimai::Message
          end
          example('Array in ds accessor') { expect(p.ds).to be_a Array }
          example('Hash in header accessor') { expect(p.header).to be_a Hash }
          example('Hash in rfc822 accessor') { expect(p.rfc822).to be_a Hash }
          example('#from returns String') { expect(p.from).to be_a String }

          example sprintf('[%s] %s#from = %s', n, cn, p.from) do
            expect(p.from.size).to be > 0
          end

          p.ds.each do |e|
            ['recipient', 'agent'].each do |ee|
              example sprintf('[%s] %s[%s] = %s', n, x, ee, e[ee]) do
                expect(e[ee].size).to be > 0
              end
            end

            %w[
              date spec reason status command action alias rhost lhost diagnosis
              feedbacktype softbounce
            ].each do |ee|
              example sprintf('[%s] %s[%s] = %s', n, x, ee, e[ee]) do
                expect(e.key?(ee)).to be true
              end
            end

            if x == 'MFILTER'
              example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
                expect(e['agent']).to be == 'm-FILTER'
              end
            elsif x == 'X4'
              example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
                expect(e['agent']).to match(/(?:qmail|X4)/)
              end
            elsif x == 'Qmail'
              example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
                expect(e['agent']).to be == 'qmail'
              end
            else
              example sprintf('[%s] %s[agent] = %s', n, x, e['agent']) do
                expect(e['agent']).to be == x
              end
            end

            example sprintf('[%s] %s[recipient] = %s', n, x, e['recipient']) do
              expect(e['recipient']).to match(/[0-9A-Za-z@-_.]+/)
              expect(e['recipient']).not_to match(/[ ]/)
            end

            example sprintf('[%s] %s[command] = %s', n, x, e['command']) do
              expect(e['command']).not_to match(/[ ]/)
            end

            if e['status'] && e['status'].size > 0
              example sprintf('[%s] %s[status] = %s', n, x, e['status']) do
                expect(e['status']).to match(/\A(?:[45][.]\d[.]\d+)\z/)
              end
            end

            if e['action'].to_s.size > 0
              example sprintf('[%s] %s[action] = %s', n, x, e['action']) do
                expect(e['action']).to match(/\A(?:fail.+|delayed|expired)\z/)
              end
            end

            ['rhost', 'lhost'].each do |ee|
              next unless e[ee]
              next unless e[ee].size > 0
              next if x =~ /\A(?:qmail|Exim|Exchange|X4)/
              example sprintf('[%s] %s[%s] = %s', n, x, ee, e[ee]) do
                expect(e[ee]).to match(/\A(?:localhost|.+[.].+)\z/)
              end
            end
          end

          o = Sisimai::Data.make( data: p )
          it 'returns Array' do
            expect(o).to be_a Array
            expect(o.size).to be > 0
          end

          o.each do |e|
            it('is Sisimai::Data object') { expect(e).to be_a Sisimai::Data }
            example '#timestamp returns Sisimai::Time' do
              expect(e.timestamp).to be_a Sisimai::Time
            end
            example '#addresser returns Sisimai::Address' do
              expect(e.addresser).to be_a Sisimai::Address
            end
            example '#recipient returns Sisimai::Address' do
              expect(e.recipient).to be_a Sisimai::Address
            end

            %w[replycode subject smtpcommand diagnosticcode diagnostictype].each do |ee|
              example sprintf('[%s] %s#%s = %s', n, x, ee, e.send(ee)) do
                expect(e.send(ee)).to be_a String
              end
            end

            example sprintf('[%s] %s#deliverystatus = %s', n, x, e.deliverystatus) do
              expect(e.deliverystatus).to be_a String
              expect(e.deliverystatus).not_to be_empty
            end

            %w[token smtpagent timezoneoffset].each do |ee|
              example sprintf('[%s] %s#%s = %s', n, x, ee, e.send(ee)) do
                expect(e.send(ee)).to be_a String
              end
            end

            example sprintf('[%s] %s#senderdomain = %s', n, x, e.senderdomain) do
              expect(e.addresser.host).to be == e.senderdomain
            end

            example sprintf('[%s] %s#destination = %s', n, x, e.destination) do
              expect(e.recipient.host).to be == e.destination
            end

            example sprintf('[%s] %s#softbounce = %s', n, x, e.softbounce) do
              expect(e.softbounce.to_s).to match(MTAChildren[x][n]['b'])
            end

            example sprintf('[%s] %s#replycode = %s', n, x, e.replycode) do
              expect(e.replycode).to match(/\A(?:[45]\d\d|)\z/)
            end

            example sprintf('[%s] %s#timezoneoffset = %s', n, x, e.timezoneoffset) do
              expect(e.timezoneoffset).to match(/\A[-+]\d{4}\z/)
            end

            example sprintf('[%s] %s#deliverystatus = %s', n, x, e.deliverystatus) do
              expect(e.deliverystatus).to match(MTAChildren[x][n]['s'])
            end

            example sprintf('[%s] %s#reason = %s', n, x, e.reason) do
              expect(e.reason).to match(MTAChildren[x][n]['r'])
            end

            example sprintf('[%s] %s#token = %s', n, x, e.token) do
              expect(e.token).to match(/\A[0-9a-f]{40}\z/)
            end

            example sprintf('[%s] %s#feedbacktype = %s', n, x, e.feedbacktype) do
              expect(e.feedbacktype).to be_empty
            end

            %w[deliverystatus diagnostictype smtpcommand lhost rhost alias listid
              action messageid]. each do |ee|
              example sprintf('[%s] %s#%s = %s', n, x, ee, e.send(ee)) do
                expect(e.send(ee)).not_to match(/[ \r]/)
              end
            end

            %w[addresser recipient].each do |ee|
              %w[user host verp alias].each do |eee|
                example sprintf('[%s] %s#%s#%s = %s', n, x, ee, eee, e.send(ee).send(eee)) do
                  expect(e.send(ee).send(eee)).not_to match(/[ \r]/)
                end
              end
            end
          end
        end
      end
    end

  end

end

