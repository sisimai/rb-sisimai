module Sisimai::Rhost
  # Imported from p5-Sisimail/lib/Sisimai/Rhost.pm
  class << self
    @@RhostClass = {
      'aspmx.l.google.com' => 'GoogleApps',
    }

    # Retrun the list of remote hosts Sisimai support
    # @return   [Array] Remote host list
    def list()
      return [ @@RhostClass.keys ]
    end

    # The value of "rhost" is listed in $RhostClass or not
    # @param    [String] argvs  Remote host name
    # @return   [Integer]       0: did not match
    #                           1: match
    def match( argvs )
      return false unless argvs.kind_of?(String)
      return true if @@RhostClass.has_key?( argvs.downcase )
      return false
    end

    # Detect the bounce reason from certain remote hosts
    # @param    [Sisimai::Data] argvs   Parsed email object
    # @return   [String]                The value of bounce reason
    def get( argvs )
      return nil unless argvs.kind_of?(Sisimai::Data)
      return argvs.reason if argvs.reason
      return nil unless @@RhostClass[ argvs.downcase ]

      reasontext = ''
      modulename = 'Sisimai::Rhost::' + @@RhostClass[ argvs.downcase ]
      rhostclass = modulename.gsub( '::', '/' )
      rhostclass = rhostclass + @@RhostClass[ argvs.downcase ]
      rhostcalss = rhostclass.downcase
      require rhostclass

      reasontext = modulename.get( argvs )
      return reasontext

    end
  end

end
