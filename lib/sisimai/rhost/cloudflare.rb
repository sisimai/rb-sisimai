module Sisimai
  module Rhost
    # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
    # of find() method when the value of "rhost" of the object is "*.mx.cloudflare.net".
    # This class is called only from Sisimai::Fact class.
    module Cloudflare
      class << self
        MessagesOf = {
          "blocked"     => ["found on one or more DNSBLs"],
          "systemerror" => ["Upstream error"],
        }.freeze

        # Detect bounce reason from Cloudflare Email Routing
        # @param    [Sisimai::Fact] argvs   Decoded email object
        # @return   [String]                The bounce reason for Cloudflare
        # @since v5.2.1
        # @see https://developers.cloudflare.com/email-routing/postmaster/
        def find(argvs)
          return "" if argvs["diagnosticcode"].empty?
          MessagesOf.each_key do |e|
            # Try to match the error message with message patterns defined in $MessagesOf
            return e if MessagesOf[e].any? { |a| argvs["diagnosticcode"].include?(a) }
          end
          return ""
        end

      end
    end
  end
end

