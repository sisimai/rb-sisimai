module Sisimai
  module Order
    # Sisimai::Order::JSON - Make optimized order list for calling MTA modules
    # for JSON formatted bounce objects
    module JSON
      # Imported from p5-Sisimail/lib/Sisimai/Order/JSON.pm
      class << self
        require 'sisimai/bite/json'

        PatternTable = {
          'keyname' => { 'notificationType' => ['Sisimai::Bite::JSON::AmazonSES'] },
        }.freeze

        make_default_order = lambda do
          # Make default order of MTA(JSON) modules to be loaded
          rv = []
          begin
            rv.concat(Sisimai::Bite::JSON.index.map { |e| 'Sisimai::Bite::JSON::' << e })
          rescue
            # Failed to load MTA(JSON) module
            next
          end
          return rv
        end
        DefaultOrder = make_default_order.call

        # @abstract Make default order of MTA(JSON) modules to be loaded
        # @return   [Array] Default order list of MTA(JSON) modules
        def default; return DefaultOrder; end

        # @abstract Make MTA(JSON) module list as a spare
        # @return   [Array] Ordered module list
        def another; return []; end

        # Make email header list in each MTA(JSON) module
        # @return   [Hash] Header list to be parsed
        def headers; return {}; end

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

