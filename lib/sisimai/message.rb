module Sisimai
  # Sisimai::Message convert bounce email text to data structure. It resolve email
  # text into an UNIX From line, the header part of the mail, delivery status, and
  # RFC822 header part. When the email given as a argument of "new" method is not a
  # bounce email, the method returns nil.
  class Message
    # Imported from p5-Sisimail/lib/Sisimai/Message.pm
    require 'sisimai/arf'
    require 'sisimai/mime'
    require 'sisimai/order'
    require 'sisimai/string'
    require 'sisimai/rfc3834'
    require 'sisimai/rfc5322'

    @@rwaccessors = [
      :from,    # [String] UNIX From line
      :header,  # [Hash]   Header part of a email
      :ds,      # [Array]  Parsed data by Sisimai::MTA::*
      :rfc822,  # [Hash]   Header part of the original message
      :catch,   # [?]      The results returned by hook method
    ]
    @@rwaccessors.each { |e| attr_accessor e }

    # Constructor of Sisimai::Message
    # @param         [String] data      Email text data
    # @param         [Hash] argvs       Module to be loaded
    # @options argvs [String] :data     Entire email message
    # @options argvs [Array]  :load     User defined MTA module list
    # @options argvs [Array]  :field    Email header names to be captured
    # @options argvs [Array]  :order    The order of MTA modules
    # @options argvs [Code]   :hook     Reference to callback method
    # @return        [Sisimai::Message] Structured email data or Undef if each
    #                                   value of the arguments are missing
    def initialize(data: '', **argvs)
      return nil if data.empty?

      email = data
      input = argvs[:input] || 'email'
      field = argvs[:field] || []
      child = nil

      if input == 'email'
        # Sisimai::Message::Email
        return nil unless email.size > 0
        email = email.scrub('?')
        email = email.gsub("\r\n", "\n")
        child = 'Sisimai::Message::Email'

      elsif input == 'json'
        # Sisimai::Message::JSON
        return nil unless email.is_a? Hash
        child = 'Sisimai::Message::JSON'

      else
        # Unsupported value in "input"
        return nil
      end

      begin
        require child.gsub('::', '/').downcase
      rescue LoadError => ce
        warn ' ***warning: Failed to load module: ' + ce.to_s
        return nil
      end

      methodargv = {
        'data'  => email,
        'hook'  => argvs[:hook] || nil,
        'field' => argvs[:field],
      }
      [:load, :order].each do |e|
        # Order of MTA, MSP modules
        next unless argvs.key?(e)
        next unless argvs[e].is_a? Array
        next if argvs[e].empty?
        methodargv[e.to_s] = argvs[e]
      end

      datasource = Module.const_get(child).make(methodargv)
      return nil unless datasource
      return nil unless datasource.key?('ds')

      @from   = datasource['from']
      @header = datasource['header']
      @ds     = datasource['ds']
      @rfc822 = datasource['rfc822']
      @catch  = datasource['catch'] || nil
    end

    # Check whether the object has valid content or not
    # @return        [True,False]   returns true if the object is void
    def void
      return true unless @ds
      return false
    end

    # Make data structure (Should be implemeneted at each child class)
    def make
      return {
        'from'   => '',  # From_ line
        'header' => {},  # Email header
        'rfc822' => '',  # Original message part
        'ds'     => [],  # Parsed data, Delivery Status
        'catch'  => nil, # Data parsed by callback method
      }
    end

    # Load MTA modules which specified at 'order' and 'load' in the argument
    # This method should be implemented at each child class
    # @since v4.20.0
    def load; return []; end

  end
end

