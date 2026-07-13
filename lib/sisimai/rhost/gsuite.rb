module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of find() method when the value of "rhost" of the object is "*.googlemail.com". This class is
    # called only from Sisimai::Fact class.
    module GSuite
      class << self
        require 'sisimai/eb'
        MessagesOf = {
          Sisimai::Eb::ReHOST => [" responded with code NXDOMAIN", "Domain name not found"],
          Sisimai::Eb::ReINET => [" had no relevant answers.", "responded with code NXDOMAIN", "Domain name not found"],
          Sisimai::Eb::Re00MX => ["Null MX"],
          Sisimai::Eb::ReUSER => ["because the address couldn't be found. Check for typos or unnecessary spaces and try again."],
        }.freeze

        # Detect bounce reason from Gsuite Mail: https://www.aol.com
        # @param    [Sisimai::Fact] argvs   Decoded email object
        # @return   [String]                The bounce reason for Gsuite
        # @since v5.2.0
        def find(argvs)
          return "" if argvs["diagnosticcode"].empty?
          statuscode = ""; statuscode = argvs["deliverystatus"][0, 1] if argvs["deliverystatus"].empty? == false
          esmtpreply = ""; esmtpreply = argvs["replycode"][0, 1]      if argvs["replycode"].empty?      == false
          reasontext = ""

          MessagesOf.each_key do |e|
            # Try to match the error message with message patterns defined in $MessagesOf
            next if MessagesOf[e].none? { |a| argvs["diagnosticcode"].include?(a) }
            next if e == Sisimai::Eb::ReINET && (statuscode == "5" || esmtpreply == "5")
            next if e == Sisimai::Eb::ReHOST && (statuscode == "4" || statuscode == "")
            next if e == Sisimai::Eb::ReHOST && (esmtpreply == "4" || esmtpreply == "")
            reasontext = e
            break
          end

          return reasontext
        end

      end
    end
  end
end

