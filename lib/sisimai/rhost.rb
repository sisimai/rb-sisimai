module Sisimai::Rhost
  # Imported from p5-Sisimail/lib/Sisimai/Rhost.pm
  class << self
    @@RhostClass = {
      'aspmx.l.google.com' => 'GoogleApps',
    }

    def list()
      # @Description  Retrun remote host list
      # @Param        <None>
      # @Return       (Array) List
      return [ @@RhostClass.keys ]
    end

    def match( argvs )
      # @Description  The rhost is listed in $RhostClass or not
      # @Param <str>  (String) Remote host name
      # @Return       (Boolean) F = did not match, T = match
      return false unless argvs.kind_of?(String)
      return true if @@RhostClass.has_key?( argvs.downcase )
      return false
    end

    def get( argvs )
      # @Description  Detect bounce reason from certain remote hosts
      # @Param <obj>  (Sisimai::Data) Parsed email object
      # @Return       (String) Bounce reason
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
