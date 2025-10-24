module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of find() method when the value of "rhost" of the object is "*.aol.com". This class is called
    # only from Sisimai::Fact class.
    module Aol
      class << self
        MessagesOf = {
          "hostunknown" => ["Host or domain name not found"],
          "notaccept"   => ["type=MX: Malformed or unexpected name server reply"],
        }.freeze

        # Detect bounce reason from Aol Mail: https://www.aol.com
        # @param    [Sisimai::Fact] argvs   Decoded email object
        # @return   [String]                The bounce reason for Aol
        # @since v5.2.0
        def find(argvs)
          return "" if argvs["diagnosticcode"].empty?
          issuedcode = argvs["diagnosticcode"]
          reasontext = ""

          MessagesOf.each_key do |e|
            # Try to match the error message with message patterns defined in $MessagesOf
            next if MessagesOf[e].none? { |a| issuedcode.include?(a) }
            reasontext = e
            break
          end

          return reasontext
        end

      end
    end
  end
end

