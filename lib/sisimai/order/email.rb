module Sisimai
  module Order
    # Sisimai::Order::Email makes optimized order list which include MTA modules
    # to be loaded on first from MTA specific headers in the bounce mail headers
    # such as X-Failed-Recipients.
    # This module are called from only Sisimai::Message::Email.
    module Email
      # Imported from p5-Sisimail/lib/Sisimai/Order/Email.pm
      class << self
        require 'sisimai/order'

        def by(group); Sisimai::Order.warn; return Sisimai::Order.by(group); end
        def default;   Sisimai::Order.warn; return Sisimai::Order.default; end
        def another;   Sisimai::Order.warn; return Sisimai::Order.another; end
        def headers;   Sisimai::Order.warn; return Sisimai::Order.headers; end
      end
    end
  end
end

