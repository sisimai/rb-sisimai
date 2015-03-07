require 'digest/sha1'

module Sisimai::String
  # Imported from p5-Sisimail/lib/Sisimai/String.pm
  class << self
    def token( addr1, addr2, epoch )
      # @Description  Create message token from addresser and recipient
      # @Param        (String) Sender address
      # @Param        (String) Recipient address
      # @Param        (Integer) Machine time of the email bounce
      # @Return       (String) Message token(MD5 hex digest)
      #               (String) Blank/failed to create token
      # @See          http://en.wikipedia.org/wiki/ASCII
      return '' unless addr1.kind_of?(String)
      return '' unless addr2.kind_of?(String)
      return '' unless epoch.is_a?(Integer)

      # Format: STX(0x02) Sender-Address RS(0x1e) Recipient-Address ETX(0x03)
      return Digest::SHA1.hexdigest(
        sprintf( "\x02%s\x1e%s\x1e%d\x03", addr1.downcase, addr2.downcase, epoch )
      )
    end

    def is_8bit( argvs )
      # @Description  8bit text or not
      # @Param <ref>  (String) String
      # @Return       false = ASCII Characters only
      #               true  = Including 8bit character
      return argvs unless argvs.kind_of?(String)
      return true unless argvs =~ /\A[\x00-\x7f]+\z/
      return false
    end

    def sweep( argvs )
      # @Description  Clean the string out
      # @Param <ref>  (String) String
      # @Return       (String) String cleaned out
      return argvs unless argvs.kind_of?(String)

      argvs = argvs.chomp
      argvs = argvs.squeeze(' ')
      argvs = argvs.gsub( /\A /, '' )
      argvs = argvs.gsub( / \z/, '' )
      argvs = argvs.sub( / [-]{2,}.+\z/, '' )

      return argvs
    end

  end

end
