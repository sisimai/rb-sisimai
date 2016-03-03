module Sisimai
  # Sisimai::String provide utilities for dealing string
  module String
    # Imported from p5-Sisimail/lib/Sisimai/String.pm
    class << self
      # End of email message as a sentinel for parsing bounce messages
      # @private
      # @return   [String] Fixed length string like a constant
      def EOM
        return '__END_OF_EMAIL_MESSAGE__'
      end

      # Create message token from addresser and recipient
      # @param  [String]  addr1 Sender address
      # @param  [String]  addr2 Recipient address
      # @param  [Integer] epoch Machine time of the email bounce
      # @return [String]        Message token(MD5 hex digest)
      # @return [String]        Blank/failed to create token
      # @see    http://en.wikipedia.org/wiki/ASCII
      def token(addr1, addr2, epoch)
        return '' unless addr1.is_a?(::String)
        return '' unless addr1.length > 0
        return '' unless addr2.is_a?(::String)
        return '' unless addr2.length > 0
        return '' unless epoch.is_a?(Integer)

        # Format: STX(0x02) Sender-Address RS(0x1e) Recipient-Address ETX(0x03)
        require 'digest/sha1'
        return Digest::SHA1.hexdigest(
          sprintf("\x02%s\x1e%s\x1e%d\x03", addr1.downcase, addr2.downcase, epoch)
        )
      end

      # The argument is 8-bit text or not
      # @param    [String] argvs  Any string to be checked
      # @return   [True,False]    false: ASCII Characters only
      #                           true:  Including 8-bit character
      def is_8bit(argvs)
        v = argvs.to_s
        return nil   if v.empty?
        return true  unless v =~ /\A[\x00-\x7f]*\z/
        return false
      end

      # Clean the string out
      # @param    [String] argv1  String to be cleaned
      # @return   [String]        Cleaned out string
      # @example  Clean up text
      #   sweep('  neko ') #=> 'neko'
      def sweep(argv1)
        return argv1 unless argv1.is_a?(::String)

        argv1 = argv1.chomp
        argv1 = argv1.squeeze(' ')
        argv1 = argv1.delete("\t")
        argv1 = argv1.gsub(/\A /, '').gsub(/ \z/, '')
        argv1 = argv1.sub(/ [-]{2,}[^ \t].+\z/, '')

        return argv1
      end

    end
  end
end
