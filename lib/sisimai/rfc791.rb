module Sisimai
  # Sisimai::RFC791 is a class related to the Internet host
  module RFC791
    class << self
      # Returns 1 if the argument is an IPv4 address
      # @param    [String] argv1  IPv4 address like "192.0.2.25"
      # @return   [Bool]          1: is an IPv4 address
      # @since v5.2.0
      def is_ipv4address(argv0)
        return false if argv0.nil? || argv0.size < 7
        octet = argv0.split(/[.]/); return false if octet.size != 4

        octet.each do |e|
          # Check each octet is between 0 and 255
          return false unless e =~ /\A[0-9]{1,3}\z/; v = e.to_i
          return false if v < 0 || v > 255
        end
        return true
      end

      # Find an IPv4 address from the given string
      # @param    [String] argv1  String including an IPv4 address
      # @return   [Array]         List of IPv4 addresses
      # @since v5.0.0
      def find(argv0)
        return nil if argv0.to_s.empty?
        return []  if argv0.size < 7

        given = argv0.dup.tr('()[],', ' ').squeeze(' ')
        return given.split(' ').select { |e| is_ipv4address(e) }
      end

    end
  end
end

