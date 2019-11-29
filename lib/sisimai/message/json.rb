module Sisimai
  class Message
    # Sisimai::Message::JSON convert from a bounce object (decoded JSON) which is
    # retrieved from some Cloud Email Deliveries API to data structure.
    class JSON
      # Imported from p5-Sisimail/lib/Sisimai/Message/JSON.pm
      require 'sisimai/message'

      # Make data structure from decoded JSON object
      # @param         [Hash] argvs   Bounce object
      # @options argvs [Hash]   data  Decoded JSON
      # @options argvs [Array]  load  User defined MTA(JSON) module list
      # @options argvs [Array]  order The order of MTA(JSON) modules
      # @options argvs [Code]   hook  Reference to callback method
      # @return        [Hash]         Resolved data structure
      def self.make(argvs)
        Sisimai::Message.warn(self.name, 'gone')
        return Sisimai::Message.make(argvs)
      end

    end
  end
end

