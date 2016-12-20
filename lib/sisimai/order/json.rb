module Sisimai
  # Sisimai::Order::JSON - Make optimized order list for calling CED modules
  module Order
    module JSON
      # Imported from p5-Sisimail/lib/Sisimai/Order/JSON.pm
      class << self
        require 'sisimai/ced'

        PatternTable = {
          'keyname' => {
            'notificationType' => [
              'Sisimai::CED::US::AmazonSES',
            ],
          },
        }

        make_default_order = lambda do
          # Make default order of CED modules to be loaded
          rv = []
          begin
            rv.concat(Sisimai::CED.index.map { |e| 'Sisimai::CED::' + e })
          rescue
            # Failed to load CED module
            next
          end
          return rv
        end
        DefaultOrder = make_default_order.call

        # Make default order of MTA/MSP modules to be loaded
        # @return   [Array] Default order list of MTA/MSP modules
        def default
          return DefaultOrder
        end

        # Get regular expression patterns for specified key name
        # @param    [String] group  Group name for "ORDER BY"
        # @return   [Hash]          Pattern table for the group
        def by(group = '')
          return {} unless group.size > 0
          return PatternTable[group] if PatternTable.key?(group)
          return {}
        end

      end
    end
  end
end


