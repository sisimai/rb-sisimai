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
          return false unless e =~ /\A[0-9]{1,3}\z/
          v = e.to_i
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

        ipv4a = []
        %w|( ) [ ] ,|.each do |e|
          # Rewrite: "mx.example.jp[192.0.2.1]" => "mx.example.jp 192.0.2.1"
          p0 = argv0.index(e); next unless p0
          argv0[p0, 1] = ' '
        end

        argv0.split(' ').each do |e|
          # Find string including an IPv4 address
          next unless e.index('.')  # IPv4 address must include "." character

          lx = e.size; next if lx < 7 || lx > 17  # 0.0.0.0 = 7, [255.255.255.255] = 17
          cu = 0  # Cursor for seeking each octet of an IPv4 address
          as = '' # ASCII Code of each character
          eo = '' # Buffer of each octet of IPv4 Address

          while cu < lx
            # Check whether each character is a number or "." or not
            as  = e[cu, 1].ord
            cu += 1

            if as < 48 || as > 57
              # The character is not a number(0-9)
              break if as      != 46  # The character is not "."
              next  if eo      == ''  # The current buffer is empty
              break if eo.to_i > 255  # The current buffer is greater than 255
              eo = ''
              next
            end
            eo += as.chr
            break if eo.to_i > 255
          end
          ipv4a << e if eo.size > 0 && eo.to_i < 256
        end
        return ipv4a
      end

    end
  end
end

