module Sisimai
  # Sisimai::Order - Parent class for making optimized order list for calling
  # MTA, MSP, and CED modules
  module Order
    # Imported from p5-Sisimail/lib/Sisimai/Order.pm
    class << self
      def by;      return {}; end
      def default; return []; end
      def another; return []; end
      def headers; return {}; end

    end
  end
end
