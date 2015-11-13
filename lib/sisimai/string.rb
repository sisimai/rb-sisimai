require 'digest/sha1'

module Sisimai::String
  # Imported from p5-Sisimail/lib/Sisimai/String.pm
  class << self

    # End of email message as a sentinel for parsing bounce messages
    # @private
    # @return   [String] Fixed length string like a constant
    def EOM()
      return '__END_OF_EMAIL_MESSAGE__';
    end

    # Create message token from addresser and recipient
    # @param  [String]  addr1 Sender address
    # @param  [String]  addr2 Recipient address
    # @param  [Integer] epoch Machine time of the email bounce
    # @return [String]        Message token(MD5 hex digest)
    # @return [String]        Blank/failed to create token
    # @see    http://en.wikipedia.org/wiki/ASCII
    def token( addr1, addr2, epoch )
      return '' unless addr1.kind_of?(String)
      return '' unless addr2.kind_of?(String)
      return '' unless epoch.is_a?(Integer)

      # Format: STX(0x02) Sender-Address RS(0x1e) Recipient-Address ETX(0x03)
      return Digest::SHA1.hexdigest(
        sprintf( "\x02%s\x1e%s\x1e%d\x03", addr1.downcase, addr2.downcase, epoch )
      )
    end

    # The argument is 8-bit text or not
    # @param    [String] argvs  Any string to be checked
    # @return   [True,False]    true:  ASCII Characters only
    #                           false: Including 8-bit character
    def is_8bit( argvs )
      return argvs unless argvs.kind_of?(String)
      return true  unless argvs =~ /\A[\x00-\x7f]+\z/
      return false
    end

    # Clean the string out
    # @param    [String] argvs  String to be cleaned
    # @return   [Scalar]        Cleaned out string
    # @example  Clean up text
    #   sweep('  neko ') #=> 'neko'
    def sweep( argvs )
      return argvs unless argvs.kind_of?(String)

      argvs = argvs.chomp
      argvs = argvs.squeeze(' ')
      argvs = argvs.gsub( /\t/, '' )
      argvs = argvs.gsub( /\A /, '' )
      argvs = argvs.gsub( / \z/, '' )
      argvs = argvs.sub( / [-]{2,}.+\z/, '' )

      return argvs
    end

  end

end
