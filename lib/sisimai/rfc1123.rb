module Sisimai
  # Sisimai::RFC1123 is a class related to the Internet host
  module RFC1123
    class << self
      # Returns "true" when the given string is a valid hostname
      # @param    [String] argv0 Hostname
      # @return   [Boolean]      false: is not a valid hostname, true: is a valid hostname
      # @since v5.2.0
      def is_validhostname(argv0 = '')
        return false unless argv0
        return false if argv0.size <   4
        return false if argv0.size > 255
        
        return false if argv0.include?(".") == false
        return false if argv0.include?("..")
        return false if argv0.include?("--")
        return false if argv0.start_with?(".")
        return false if argv0.start_with?("-")
        return false if argv0.end_with?("-")

        valid = true
        token = argv0.split('.')
        argv0.upcase.split('').each do |e|
          # Check each characater is a number or an alphabet
          f = e.ord
          valid = false if f <  45;           # 45 = '-'
          valid = false if f == 47;           # 47 = '/'
          valid = false if f >  57 && f < 65; # 57 = '9', 65 = 'A'
          valid = false if f >  90            # 90 = 'Z'
        end
        return false if valid == false
        return false if token[-1] =~ /\d/
        return valid
      end

    end
  end
end

