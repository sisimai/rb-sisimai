module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of find() method when the value of "rhost" of the object is "*.email.ua". This class is called
    # only Sisimai::Fact class.
    module IUA
      class << self
        require 'sisimai/eb'
        ErrorCodes = {
          # https://mail.i.ua/err/$(CODE)
          '1'  => Sisimai::Eb::RePASS, # The use of SMTP as mail gate is forbidden.
          '2'  => Sisimai::Eb::ReUSER, # User is not found.
          '3'  => Sisimai::Eb::ReQUIT, # Mailbox was not used for more than 3 months
          '4'  => Sisimai::Eb::ReFULL, # Mailbox is full.
          '5'  => Sisimai::Eb::ReRATE, # Letter sending limit is exceeded.
          '6'  => Sisimai::Eb::RePASS, # Use SMTP of your provider to send mail.
          '7'  => Sisimai::Eb::ReBLOC, # Wrong value if command HELO/EHLO parameter.
          '8'  => Sisimai::Eb::ReFROM, # Couldn't check sender address.
          '9'  => Sisimai::Eb::ReBLOC, # IP-address of the sender is blacklisted.
          '10' => Sisimai::Eb::ReFILT  # Not in the list Mail address management.
        }.freeze

        # Detect bounce reason from https://www.i.ua/
        # @param    [Sisimai::Fact] argvs   Decoded email object
        # @return   [String]                The bounce reason at https://www.i.ua/
        def find(argvs)
          return "" if argvs["diagnosticcode"].empty?
          issuedcode = argvs['diagnosticcode'].downcase
          codenumber = issuedcode.index('.i.ua/err/') > 0 ? issuedcode[issuedcode.index('/err/') + 5, 2] : 0
          codenumber = codenumber[0, 1] if codenumber.index('/') == 1

          return ErrorCodes[codenumber] || ''
        end

      end
    end
  end
end

