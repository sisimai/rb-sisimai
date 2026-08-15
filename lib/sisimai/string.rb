module Sisimai
  # Sisimai::String provide utilities for dealing string
  module String
    class << self
      Match = {
        html: %r|<html[ >].+?</html>|im,
        body: %r|<head>.+</head>.*<body[ >].+</body>|im,
      }

      # The argument is 8-bit text or not
      # @param    [String] argvs  Any string to be checked
      # @return   [Boolean]       false: ASCII Characters only, true: Including 8-bit character
      def is_8bit(argvs)
        v = argvs.to_s
        return false if v.empty?
        return true  if v !~ /\A[\x00-\x7f]*\z/
        return false
      end

      # Check if each element of the 2nd argument is aligned in the 1st argument or not
      # @param    [String] argv1  String to be checked
      # @param    [Array]  argv2  List including the ordered strings
      # @return   [Boolean]
      # @since v5.0.0
      def aligned(argv1, argv2)
        return false if argv1.to_s.empty? || argv2.is_a?(Array) == false || argv2.size < 2

        align = -1
        right =  0
        argv2.each do |e|
          # Get the position of each element in the 1st argument using index()
          p = argv1.index(e, align + 1)
          break if p == nil         # Break this loop when there is no string in the 1st argument
          align  = e.length + p - 1 # There is an aligned string in the 1st argument
          right += 1
        end

        return true if right == argv2.size
        return false
      end

      # Convert given HTML text to plain text
      # @param    [String]  argv1 HTML text
      # @param    [Boolean] loose Loose check flag
      # @return   [String]  Plain text
      def to_plain(argv1 = '', loose = false)
        return "" if argv1.empty?

        plain = argv1
        if loose || plain =~ Match[:html] || plain =~ Match[:body]
          # 1. Remove <head>...</head>
          # 2. Remove <style>...</style>
          # 3. <a href = 'http://...'>...</a> to " http://... "
          # 4. <a href = 'mailto:...'>...</a> to " Value <mailto:...> "
          plain.scrub!('?')
          plain = plain.gsub(%r|<head>.+</head>|im, '')      if plain.downcase.include?('</head>')
          plain = plain.gsub(%r|<style.+?>.+</style>|im, '') if plain.downcase.include?('</style>')
          plain = plain.gsub(%r|<a\s+href\s*=\s*['"](https?://.+?)['"].*?>(.*?)</a>|i, '[\2](\1)')
          plain = plain.gsub(%r|<a\s+href\s*=\s*["']mailto:([^\s]+?)["']>(.*?)</a>|i, '[\2](mailto:\1)')
          plain = plain.gsub(/<[^<@>]+?>\s*/, ' ')              # Delete HTML tags except <neko@example.jp>
          plain = plain.gsub(/&lt;/, '<').gsub(/&gt;/, '>')     # Convert to angle brackets
          plain = plain.gsub(/&amp;/, '&').gsub(/&nbsp;/, ' ')  # Convert to "&"
          plain = plain.gsub(/&quot;/, '"').gsub(/&apos;/, "'") # Convert to " and '
          plain = "#{plain.squeeze(' ')}\n" if argv1.size > plain.size
        end

        return plain
      end

      # Convert given string to UTF-8
      # @param    [String] argv1  String to be converted
      # @param    [String] argv2  Encoding name before converting
      # @return   [String]        UTF-8 Encoded string
      def to_utf8(argv1 = '', argv2 = nil)
        return "" if argv1.empty?

        encodefrom = argv2 || false
        getencoded = ''

        begin
          # Try to convert the string to UTF-8
          getencoded = if encodefrom
                         # String#encode('UTF-8', <FROM>)
                         argv1.encode('UTF-8', encodefrom)
                       else
                         # Force encoding to UTF-8
                         argv1.force_encoding('UTF-8')
                       end
        rescue
          # Unknown encoding name or failed to encode
          getencoded = argv1.force_encoding('UTF-8')
        end
        return getencoded.scrub('?')
      end

    end
  end
end
