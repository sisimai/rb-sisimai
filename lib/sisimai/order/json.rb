module Sisimai
  module Order
    # Sisimai::Order::JSON - Make optimized order list for calling MTA modules
    # for JSON formatted bounce objects
    module JSON
      # Imported from p5-Sisimail/lib/Sisimai/Order/JSON.pm
      class << self
        require 'sisimai/order'

        def default; Sisimai::Order.warn('forjson'); return Sisimai::Order.default; end
        def by(group); Sisimai::Order.warn('gone'); return Sisimai::Order.by(group); end
      end
    end
  end
end

