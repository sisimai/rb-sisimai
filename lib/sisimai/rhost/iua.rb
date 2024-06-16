module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of get() method when the value of "rhost" of the object is "*.email.ua". This class is called
    # only Sisimai::Fact class.
    module IUA
      class << self
        ErrorCodes = {
          # https://mail.i.ua/err/$(CODE)
          '1'  => 'norelaying',  # The use of SMTP as mail gate is forbidden.
          '2'  => 'userunknown', # User is not found.
          '3'  => 'suspend',     # Mailbox was not used for more than 3 months
          '4'  => 'mailboxfull', # Mailbox is full.
          '5'  => 'toomanyconn', # Letter sending limit is exceeded.
          '6'  => 'norelaying',  # Use SMTP of your provider to send mail.
          '7'  => 'blocked',     # Wrong value if command HELO/EHLO parameter.
          '8'  => 'rejected',    # Couldn't check sender address.
          '9'  => 'blocked',     # IP-address of the sender is blacklisted.
          '10' => 'filtered',    # Not in the list Mail address management.
        }.freeze

        # Detect bounce reason from https://www.i.ua/
        # @param    [Sisimai::Fact] argvs   Decoded email object
        # @return   [String]                The bounce reason at https://www.i.ua/
        def get(argvs)
          return argvs['reason'] unless argvs['reason'].empty?
          issuedcode = argvs['diagnosticcode'].downcase
          codenumber = issuedcode.index('.i.ua/err/') > 0 ? issuedcode[issuedcode.index('/err/') + 5, 2] : 0
          codenumber = codenumber[0, 1] if codenumber.index('/') == 1

          return ErrorCodes[codenumber] || ''
        end

      end
    end
  end
end

