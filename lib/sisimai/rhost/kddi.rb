module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of find() method when the value of "rhost" of the object is "lsean.ezweb.ne.jp" or "msmx.au.com".
    # This class is called only Sisimai::Fact class.
    module KDDI
      class << self
        require 'sisimai/eb'
        MessagesOf = {
          Sisimai::Eb::ReFILT => '550 : user unknown',  # The response was: 550 : User unknown
          Sisimai::Eb::ReUSER => '>: user unknown',     # The response was: 550 <...>: User unknown
        }.freeze

        # Detect bounce reason from au (KDDI)
        # @param    [Sisimai::Fact] argvs   Decoded email object
        # @return   [String]                The bounce reason for au.com or ezweb.ne.jp
        # @since v4.22.6
        def find(argvs)
          return "" if argvs["diagnosticcode"].empty?
          issuedcode = argvs['diagnosticcode'].downcase
          reasontext = ''

          MessagesOf.each_key do |e|
            # Try to match the error message with message patterns defined in $MessagesOf
            next if issuedcode.include?(MessagesOf[e]) == false
            reasontext = e
            break
          end

          return reasontext
        end

      end
    end
  end
end


