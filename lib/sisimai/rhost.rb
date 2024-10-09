module Sisimai
  # Sisimai::Rhost detects the bounce reason from the content of Sisimai::Fact object as an argument
  # of find() method when the value of rhost of the object is listed in the results of Sisimai::Rhost
  # ->list method. This class is called only Sisimai::Fact class.
  module Rhost
    class << self
      RhostClass = {
        'Apple'     => ['.mail.icloud.com', '.apple.com', '.me.com'],
        'Cox'       => ['cox.net'],
        'FrancePTT' => ['.laposte.net', '.orange.fr', '.wanadoo.fr'],
        'GoDaddy'   => ['smtp.secureserver.net', 'mailstore1.secureserver.net'],
        'Google'    => ['aspmx.l.google.com', 'gmail-smtp-in.l.google.com'],
        'IUA'       => ['.email.ua'],
        'KDDI'      => ['.ezweb.ne.jp', 'msmx.au.com'],
        'Microsoft' => ['.prod.outlook.com', '.protection.outlook.com'],
        'Mimecast'  => ['.mimecast.com'],
        'NTTDOCOMO' => ['mfsmax.docomo.ne.jp'],
        'Spectrum'  => ['charter.net'],
        'Tencent'   => ['.qq.com'],
        'YahooInc'  => ['.yahoodns.net'],
      }.freeze

      # Detect the bounce reason from certain remote hosts
      # @param    [Hash]   argvs  Decoded email data
      # @return   [String]        The value of bounce reason
      def find(argvs)
        return nil if argvs['diagnosticcode'].empty?

        remotehost = argvs['rhost'].downcase
        domainpart = argvs['destination'].downcase
        return nil if (remotehost + domainpart).empty?

        rhostmatch = nil
        rhostclass = ''
        modulename = ''

        RhostClass.each_key do |e|
          # Try to match with each value of RhostClass
          rhostmatch   = true if RhostClass[e].any? { |a| remotehost.end_with?(a) }
          rhostmatch ||= true if RhostClass[e].any? { |a| a.end_with?(domainpart) }
          next unless rhostmatch

          modulename = 'Sisimai::Rhost::' << e
          rhostclass = 'sisimai/rhost/' << e.downcase
          break
        end
        return nil if rhostclass.empty?

        require rhostclass
        reasontext = Module.const_get(modulename).find(argvs)
        return nil if reasontext.empty?
        return reasontext
      end
    end
  end
end

